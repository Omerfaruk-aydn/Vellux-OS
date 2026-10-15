use serde::{Deserialize, Serialize};

/// Pre-calibrated spring parameters for human interface interactions.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct SpringConfig {
    /// Spring stiffness constant (k) in N/m. Higher values yield faster return.
    pub stiffness: f64,
    /// Viscous damping coefficient (c) in N·s/m. Controls oscillation decay.
    pub damping: f64,
    /// Simulated inertial mass (m) in kg.
    pub mass: f64,
}

impl Default for SpringConfig {
    fn default() -> Self {
        Self::DEFAULT_SMOOTH
    }
}

impl SpringConfig {
    /// Ultra-responsive dock icon magnification (high stiffness, critical damping)
    pub const DOCK_MAGNIFY: Self = Self {
        stiffness: 480.0,
        damping: 32.0,
        mass: 0.8,
    };

    /// Icon launch bounce (playful, energetic spring with controlled overshoot)
    pub const DOCK_BOUNCE: Self = Self {
        stiffness: 260.0,
        damping: 14.0,
        mass: 1.0,
    };

    /// Window presentation and sheet pull-down (natural weighted drape)
    pub const WINDOW_PRESENT: Self = Self {
        stiffness: 320.0,
        damping: 26.0,
        mass: 1.0,
    };

    /// Standard smooth transition
    pub const DEFAULT_SMOOTH: Self = Self {
        stiffness: 300.0,
        damping: 24.0,
        mass: 1.0,
    };
}

/// Dynamic state of a spring simulation.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct SpringState {
    pub value: f64,
    pub velocity: f64,
    pub settled: bool,
}

/// Continuous Mass-Spring-Damper Solver.
/// Evaluates: m*(d²x/dt²) + c*(dx/dt) + k*(x - x_target) = 0
/// Solved via Symplectic Semi-Implicit Euler integration for unconditional energy stability.
#[derive(Debug, Clone)]
pub struct Spring {
    pub config: SpringConfig,
    pub current: f64,
    pub target: f64,
    pub velocity: f64,
    threshold: f64,
}

impl Spring {
    pub fn new(config: SpringConfig, initial_value: f64) -> Self {
        Self {
            config,
            current: initial_value,
            target: initial_value,
            velocity: 0.0,
            threshold: 0.0005,
        }
    }

    pub fn set_target(&mut self, target: f64) {
        self.target = target;
    }

    pub fn set_target_with_impulse(&mut self, target: f64, impulse_velocity: f64) {
        self.target = target;
        self.velocity = impulse_velocity;
    }

    /// Advances the simulation by monotonic time delta `dt` in seconds.
    pub fn step(&mut self, dt: f64) -> SpringState {
        // Clamp dt to avoid simulation divergence on frame drops
        let dt = dt.clamp(0.0001, 0.0333);

        let displacement = self.current - self.target;
        let spring_force = -self.config.stiffness * displacement;
        let damping_force = -self.config.damping * self.velocity;
        let acceleration = (spring_force + damping_force) / self.config.mass;

        // Semi-implicit Euler integration (updates velocity first, then position)
        self.velocity += acceleration * dt;
        self.current += self.velocity * dt;

        let settled = displacement.abs() < self.threshold && self.velocity.abs() < self.threshold;
        if settled {
            self.current = self.target;
            self.velocity = 0.0;
        }

        SpringState {
            value: self.current,
            velocity: self.velocity,
            settled,
        }
    }
}
