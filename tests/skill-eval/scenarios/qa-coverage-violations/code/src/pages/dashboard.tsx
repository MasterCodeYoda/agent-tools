// Dashboard page — has NL spec but no generated test
export function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      <div className="stats">
        <div>Total Users: 1,234</div>
        <div>Active Today: 567</div>
        <div>Revenue: $12,345</div>
      </div>
      <div className="recent-activity">
        <h2>Recent Activity</h2>
        <ul>
          <li>User signed up</li>
          <li>Order placed</li>
          <li>Payment received</li>
        </ul>
      </div>
    </div>
  );
}
