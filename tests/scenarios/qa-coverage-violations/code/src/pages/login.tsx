// Login page — app uses data-testid="auth-form" after refactor
export function LoginPage() {
  return (
    <div data-testid="auth-form">
      <h1>Sign In</h1>
      <input type="email" name="email" placeholder="Email" />
      <input type="password" name="password" placeholder="Password" />
      <button type="submit">Sign In</button>
    </div>
  );
}
