// Registration page — now has 3 steps (spec only describes 2)
// VIOLATION QCV-06: Spec says 2-step, app is now 3-step
export function RegistrationPage() {
  return (
    <div>
      <h1>Create Account</h1>
      {/* Step 1: Email */}
      <div data-step="1">
        <input type="email" name="email" placeholder="Email" />
        <button>Next</button>
      </div>
      {/* Step 2: Password */}
      <div data-step="2">
        <input type="password" name="password" placeholder="Password" />
        <input type="password" name="confirm" placeholder="Confirm Password" />
        <button>Next</button>
      </div>
      {/* Step 3: Email Verification — NEW, not in spec */}
      <div data-step="3">
        <p>We sent a verification code to your email.</p>
        <input type="text" name="code" placeholder="Verification code" />
        <button>Verify & Create Account</button>
      </div>
    </div>
  );
}
