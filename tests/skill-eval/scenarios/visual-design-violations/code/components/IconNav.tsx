// Icon navigation — PLANTED VIOLATIONS for evolve scenario testing.

interface IconNavProps {
  items: Array<{ icon: string; label: string; href: string }>;
}

export function IconNav({ items }: IconNavProps) {
  return (
    <nav className="icon-nav" style={{ display: "flex", gap: "4px" }}>
      {items.map((item) => (
        // VIOLATION VDV-01: Touch target is 24x24px — below 44px minimum
        // No padding extension, no invisible hit area expansion
        <a
          key={item.href}
          href={item.href}
          style={{
            width: "24px",
            height: "24px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: "14px",
          }}
          title={item.label}
        >
          {item.icon}
        </a>
      ))}
    </nav>
  );
}
