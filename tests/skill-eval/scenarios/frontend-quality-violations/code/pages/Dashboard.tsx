// Dashboard page — PLANTED VIOLATIONS for evolve scenario testing.
// VIOLATION FQV-03: God component — 280+ lines, handles everything inline.

import { useState, useEffect } from "react";
import { useUserStore } from "../store";

interface User {
  id: number;
  name: string;
  email: string;
  avatar: string;
  role: string;
}

interface Order {
  id: number;
  total: number;
  status: string;
  items: Array<{ name: string; qty: number }>;
}

// VIOLATION FQV-08: State duplication — local state duplicates Zustand store
export function Dashboard() {
  const [users, setUsers] = useState<User[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [filter, setFilter] = useState("all");
  const [sortBy, setSortBy] = useState("date");
  const [isEditing, setIsEditing] = useState(false);
  const [editName, setEditName] = useState("");
  const [editEmail, setEditEmail] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [notifications, setNotifications] = useState<string[]>([]);
  const [theme, setTheme] = useState("light");

  // State duplication: user also in Zustand store
  const storeUser = useUserStore((s) => s.currentUser);
  const storeSetUser = useUserStore((s) => s.setCurrentUser);

  // VIOLATION FQV-06: No loading state — jumps from empty to populated
  useEffect(() => {
    fetch("/api/users")
      .then((res) => res.json())
      .then((data) => {
        setUsers(data.users);
        // Duplicating into store too
        if (data.users[0]) storeSetUser(data.users[0]);
      });
  }, []);

  useEffect(() => {
    fetch("/api/orders")
      .then((res) => res.json())
      .then((data) => setOrders(data.orders));
  }, []);

  const filteredUsers = users.filter((u) => {
    if (filter === "all") return true;
    return u.role === filter;
  });

  const sortedOrders = [...orders].sort((a, b) => {
    if (sortBy === "total") return b.total - a.total;
    return b.id - a.id;
  });

  const handleEdit = (user: User) => {
    setSelectedUser(user);
    setEditName(user.name);
    setEditEmail(user.email);
    setIsEditing(true);
  };

  const handleSave = async () => {
    if (!selectedUser) return;
    await fetch(`/api/users/${selectedUser.id}`, {
      method: "PUT",
      body: JSON.stringify({ name: editName, email: editEmail }),
    });
    setUsers((prev) =>
      prev.map((u) =>
        u.id === selectedUser.id ? { ...u, name: editName, email: editEmail } : u
      )
    );
    setIsEditing(false);
  };

  const handleDelete = async (userId: number) => {
    await fetch(`/api/users/${userId}`, { method: "DELETE" });
    setUsers((prev) => prev.filter((u) => u.id !== userId));
    setNotifications((prev) => [...prev, `User ${userId} deleted`]);
  };

  const totalRevenue = orders.reduce((sum, o) => sum + o.total, 0);
  const activeOrders = orders.filter((o) => o.status === "active").length;

  // VIOLATION FQV-05: No error boundary wrapping this component
  return (
    <div className={`dashboard ${theme}`}>
      <header>
        <h1>Dashboard</h1>
        <button onClick={() => setTheme(theme === "light" ? "dark" : "light")}>
          Toggle Theme
        </button>
      </header>

      <div className="stats">
        <div>Total Revenue: ${totalRevenue.toFixed(2)}</div>
        <div>Active Orders: {activeOrders}</div>
        <div>Users: {users.length}</div>
      </div>

      <div className="filters">
        <select value={filter} onChange={(e) => setFilter(e.target.value)}>
          <option value="all">All Roles</option>
          <option value="admin">Admin</option>
          <option value="user">User</option>
        </select>
        <input
          placeholder="Search..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* VIOLATION FQV-04: Prop drilling — user passed 4 levels deep */}
      <div className="user-section">
        {filteredUsers.map((user) => (
          <UserSection key={user.id} user={user} onEdit={handleEdit} onDelete={handleDelete} />
        ))}
      </div>

      <div className="orders-section">
        <h2>Orders</h2>
        <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
          <option value="date">By Date</option>
          <option value="total">By Total</option>
        </select>
        {sortedOrders.map((order) => (
          <div key={order.id} className="order-row">
            <span>Order #{order.id}</span>
            <span>${order.total.toFixed(2)}</span>
            <span>{order.status}</span>
          </div>
        ))}
      </div>

      {isEditing && selectedUser && (
        <div className="modal">
          <h2>Edit User</h2>
          <input value={editName} onChange={(e) => setEditName(e.target.value)} />
          <input value={editEmail} onChange={(e) => setEditEmail(e.target.value)} />
          <button onClick={handleSave}>Save</button>
          <button onClick={() => setIsEditing(false)}>Cancel</button>
        </div>
      )}

      {notifications.length > 0 && (
        <div className="notifications">
          {notifications.map((n, i) => (
            <div key={i} className="notification">{n}</div>
          ))}
        </div>
      )}
    </div>
  );
}

// Prop drilling chain: Dashboard → UserSection → UserCard → UserAvatar
function UserSection({
  user,
  onEdit,
  onDelete,
}: {
  user: User;
  onEdit: (u: User) => void;
  onDelete: (id: number) => void;
}) {
  return (
    <div className="user-section-item">
      <UserCard user={user} onEdit={onEdit} onDelete={onDelete} />
    </div>
  );
}

function UserCard({
  user,
  onEdit,
  onDelete,
}: {
  user: User;
  onEdit: (u: User) => void;
  onDelete: (id: number) => void;
}) {
  return (
    <div className="user-card">
      <UserAvatar user={user} />
      <div>
        <h3>{user.name}</h3>
        <p>{user.email}</p>
      </div>
      <button onClick={() => onEdit(user)}>Edit</button>
      <button onClick={() => onDelete(user.id)}>Delete</button>
    </div>
  );
}

function UserAvatar({ user }: { user: User }) {
  return <img src={user.avatar} alt={user.name} className="avatar" />;
}
