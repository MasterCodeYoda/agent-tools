// Filter bar — PLANTED VIOLATIONS for evolve scenario testing.

import { useState } from "react";

const categories = ["All", "Frontend", "Backend", "DevOps", "Design"];
const sortOptions = ["Newest", "Popular", "Trending"];

export function FilterBar({ onFilter }: { onFilter: (cat: string, sort: string) => void }) {
  // VIOLATION VDV-07: State not persisted in URL
  // Refreshing the page loses filter selections
  // Sharing the URL doesn't share the filtered view
  const [category, setCategory] = useState("All");
  const [sortBy, setSortBy] = useState("Newest");

  const handleCategoryChange = (cat: string) => {
    setCategory(cat);
    onFilter(cat, sortBy);
  };

  const handleSortChange = (sort: string) => {
    setSortBy(sort);
    onFilter(category, sort);
  };

  return (
    <div className="filter-bar" style={{ display: "flex", gap: "8px", padding: "12px 0" }}>
      {categories.map((cat) => (
        // VIOLATION VDV-08: cursor:pointer on action buttons
        // Pointer cursor should be reserved for navigation (links)
        // Buttons should use the default cursor
        <button
          key={cat}
          onClick={() => handleCategoryChange(cat)}
          style={{
            cursor: "pointer", // Should be "default" for buttons
            padding: "8px 16px",
            borderRadius: "20px",
            border: "1px solid #ddd",
            backgroundColor: category === cat ? "#333" : "#fff",
            color: category === cat ? "#fff" : "#333",
          }}
        >
          {cat}
        </button>
      ))}

      <select
        value={sortBy}
        onChange={(e) => handleSortChange(e.target.value)}
        style={{ marginLeft: "auto", cursor: "pointer" }}
      >
        {sortOptions.map((opt) => (
          <option key={opt} value={opt}>
            {opt}
          </option>
        ))}
      </select>
    </div>
  );
}
