/**
 * Vellux OS Spring Physics & Dynamics Engine
 * Replaces linear easing with real-world second-order differential equations:
 * F = -k*x - c*v (Hooke's Law + viscous damping)
 */

export class SpringSimulation {
  /**
   * @param {Object} config
   * @param {number} config.stiffness Spring constant k (typical 200 - 500)
   * @param {number} config.damping Damping coefficient c (typical 20 - 40)
   * @param {number} config.mass Object mass m (typical 1.0)
   * @param {number} config.initialVelocity Starting impulse
   */
  constructor({ stiffness = 320, damping = 24, mass = 1.0, initialVelocity = 0 } = {}) {
    this.stiffness = stiffness;
    this.damping = damping;
    this.mass = mass;
    this.velocity = initialVelocity;
    this.current = 0;
    this.target = 0;
  }

  setTarget(target, initialVelocity = null) {
    this.target = target;
    if (initialVelocity !== null) {
      this.velocity = initialVelocity;
    }
  }

  /**
   * Advance simulation by delta time (dt in seconds)
   * Solved using Symplectic Euler integration for unconditional stability.
   */
  step(dt) {
    // Bound dt to prevent explosion on background tab throttling
    const clampedDt = Math.min(dt, 0.032);

    const displacement = this.current - this.target;
    const springForce = -this.stiffness * displacement;
    const dampingForce = -this.damping * this.velocity;
    const acceleration = (springForce + dampingForce) / this.mass;

    this.velocity += acceleration * clampedDt;
    this.current += this.velocity * clampedDt;

    const isSettled = Math.abs(displacement) < 0.001 && Math.abs(this.velocity) < 0.001;
    if (isSettled) {
      this.current = this.target;
      this.velocity = 0;
    }

    return {
      value: this.current,
      settled: isSettled,
    };
  }
}

/**
 * Pre-calibrated Human Interface Spring Profiles for Vellux OS
 */
export const SpringProfiles = {
  // Floating Dock Icon Magnification (High responsiveness, slight gentle overshoot)
  dockMagnify: {
    stiffness: 420,
    damping: 28,
    mass: 0.8,
  },

  // Dock Icon Launch Bounce (Playful, energetic jump)
  dockBounce: {
    stiffness: 280,
    damping: 14,
    mass: 1.0,
  },

  // Window Open & Expand (Smooth deceleration, natural momentum)
  windowPresent: {
    stiffness: 300,
    damping: 26,
    mass: 1.0,
  },

  // Control Center Drawer Reveal (Tactile, weighted sheet pull)
  sheetPull: {
    stiffness: 360,
    damping: 32,
    mass: 1.1,
  },

  // Context Menu Pop & Tooltips (Snappy micro-interactions)
  microInteraction: {
    stiffness: 550,
    damping: 35,
    mass: 0.6,
  },
};
