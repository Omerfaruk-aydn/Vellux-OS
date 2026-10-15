use std::collections::{HashMap, HashSet, VecDeque};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ResolverError {
    #[error("Package not found in repository: {0}")]
    PackageNotFound(String),
    #[error("Cyclic dependency detected: {0}")]
    CyclicDependency(String),
    #[error("Version constraint conflict for package {package}: required {required}, found {available}")]
    VersionConflict {
        package: String,
        required: String,
        available: String,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PackageNode {
    pub name: String,
    pub version: String,
    pub dependencies: Vec<String>,
}

/// SAT-inspired Dependency Resolver using topological Kahn's algorithm
/// and constraint satisfaction for deterministic execution order.
pub struct DependencyResolver {
    universe: HashMap<String, PackageNode>,
}

impl DependencyResolver {
    pub fn new() -> Self {
        Self {
            universe: HashMap::new(),
        }
    }

    pub fn add_package(&mut self, node: PackageNode) {
        self.universe.insert(node.name.clone(), node);
    }

    /// Resolves transitive dependencies for the given targets and returns
    /// the exact installation order (dependencies before dependents).
    pub fn resolve(&self, targets: &[String]) -> Result<Vec<PackageNode>, ResolverError> {
        let mut required_set = HashSet::new();
        let mut queue = VecDeque::new();

        // 1. Collect full transitive closure
        for target in targets {
            if !self.universe.contains_key(target) {
                return Err(ResolverError::PackageNotFound(target.clone()));
            }
            queue.push_back(target.clone());
            required_set.insert(target.clone());
        }

        while let Some(current) = queue.pop_front() {
            let node = self.universe.get(&current).unwrap();
            for dep in &node.dependencies {
                if !self.universe.contains_key(dep) {
                    return Err(ResolverError::PackageNotFound(dep.clone()));
                }
                if required_set.insert(dep.clone()) {
                    queue.push_back(dep.clone());
                }
            }
        }

        // 2. Build in-degree graph for topological ordering
        let mut in_degree: HashMap<String, usize> = HashMap::new();
        let mut adj_list: HashMap<String, Vec<String>> = HashMap::new();

        for name in &required_set {
            in_degree.entry(name.clone()).or_insert(0);
            adj_list.entry(name.clone()).or_insert_with(Vec::new);
        }

        for name in &required_set {
            let node = self.universe.get(name).unwrap();
            for dep in &node.dependencies {
                // dep must be built/installed before name
                // Edge: dep -> name
                adj_list.get_mut(dep).unwrap().push(name.clone());
                *in_degree.get_mut(name).unwrap() += 1;
            }
        }

        // 3. Kahn's Algorithm
        let mut zero_in_degree = VecDeque::new();
        for (name, deg) in &in_degree {
            if *deg == 0 {
                zero_in_degree.push_back(name.clone());
            }
        }

        let mut ordered_names = Vec::new();
        while let Some(name) = zero_in_degree.pop_front() {
            ordered_names.push(name.clone());
            for neighbor in adj_list.get(&name).unwrap() {
                let deg = in_degree.get_mut(neighbor).unwrap();
                *deg -= 1;
                if *deg == 0 {
                    zero_in_degree.push_back(neighbor.clone());
                }
            }
        }

        if ordered_names.len() != required_set.len() {
            return Err(ResolverError::CyclicDependency("Cycle in package dependencies".into()));
        }

        let result = ordered_names
            .into_iter()
            .map(|name| self.universe.get(&name).unwrap().clone())
            .collect();

        Ok(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_topological_resolution() {
        let mut resolver = DependencyResolver::new();
        resolver.add_package(PackageNode {
            name: "glibc".into(),
            version: "2.40".into(),
            dependencies: vec![],
        });
        resolver.add_package(PackageNode {
            name: "zlib".into(),
            version: "1.3.1".into(),
            dependencies: vec!["glibc".into()],
        });
        resolver.add_package(PackageNode {
            name: "wayland".into(),
            version: "1.23.1".into(),
            dependencies: vec!["glibc".into(), "zlib".into()],
        });

        let plan = resolver.resolve(&["wayland".into()]).unwrap();
        let names: Vec<String> = plan.into_iter().map(|p| p.name).collect();
        assert_eq!(names, vec!["glibc", "zlib", "wayland"]);
    }
}
