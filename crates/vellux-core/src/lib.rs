//! Vellux Core — Mathematical Foundations & Physics Engine
//! Implements real-time second-order differential mass-spring-damper solvers
//! for flicker-free, 120Hz/144Hz high-refresh Wayland shell interactions.

pub mod physics;
pub mod protocol;

pub use physics::{Spring, SpringConfig, SpringState};
