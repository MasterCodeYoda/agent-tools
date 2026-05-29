// Settings page — recently added, no NL spec
// VIOLATION QCV-07: New feature with no test coverage
export function SettingsPage() {
  return (
    <div>
      <h1>Settings</h1>
      <section>
        <h2>Profile</h2>
        <input type="text" name="displayName" placeholder="Display name" />
        <input type="email" name="email" placeholder="Email" />
        <button>Save Changes</button>
      </section>
      <section>
        <h2>Notifications</h2>
        <label><input type="checkbox" name="emailNotifs" /> Email notifications</label>
        <label><input type="checkbox" name="pushNotifs" /> Push notifications</label>
      </section>
      <section>
        <h2>Danger Zone</h2>
        <button className="danger">Delete Account</button>
      </section>
    </div>
  );
}
