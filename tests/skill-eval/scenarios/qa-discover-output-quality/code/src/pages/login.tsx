// Login page — qa:discover should generate an auth flow spec for this
export function LoginPage() {
  return (
    <div>
      <h1>Sign In</h1>
      <form action="/api/auth/login" method="POST">
        <label htmlFor="email">Email</label>
        <input id="email" type="email" name="email" required />
        <label htmlFor="password">Password</label>
        <input id="password" type="password" name="password" required />
        <button type="submit">Sign In</button>
      </form>
      <a href="/forgot-password">Forgot password?</a>
      <a href="/register">Create account</a>
      <p className="error-message" role="alert"></p>
    </div>
  );
}
