// User badge — PLANTED VIOLATION for evolve scenario testing.
// VDV-09: Design token inconsistency

interface User {
  name: string;
  role: "admin" | "editor" | "viewer";
  avatarUrl: string;
}

export function UserBadge({ user }: { user: User }) {
  // VIOLATION VDV-09: Hardcoded colors and spacing throughout
  // instead of using CSS custom properties or a theme object.
  // Other components in this app use #333 for text and #eee for borders,
  // but this component uses its own palette — classic design token drift.
  const roleColors: Record<string, string> = {
    admin: "#e74c3c",   // ad-hoc red — not from any token set
    editor: "#2ecc71",  // ad-hoc green — not from any token set
    viewer: "#3498db",  // ad-hoc blue — not from any token set
  };

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: "13px",           // magic number — not a standard spacing token
        padding: "11px 17px",  // magic numbers — not standard spacing tokens
        borderRadius: "6px",   // other components use 8px or 20px
        backgroundColor: "#fafafa",  // ad-hoc background — not from token set
        border: `2px solid ${roleColors[user.role]}`,  // ad-hoc colors
      }}
    >
      <img
        src={user.avatarUrl}
        alt={user.name}
        width={32}
        height={32}
        style={{ borderRadius: "50%" }}
      />
      <div>
        <span style={{ fontWeight: 600, color: "#1a1a1a" }}>{user.name}</span>
        <span
          style={{
            marginLeft: "8px",
            fontSize: "11px",  // ad-hoc font size
            color: roleColors[user.role],
            textTransform: "uppercase",
            letterSpacing: "0.5px",
          }}
        >
          {user.role}
        </span>
      </div>
    </div>
  );
}
