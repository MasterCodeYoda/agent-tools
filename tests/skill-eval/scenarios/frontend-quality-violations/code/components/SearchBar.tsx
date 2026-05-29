// Search bar component — PLANTED VIOLATIONS for evolve scenario testing.

import { useState } from "react";

interface SearchBarProps {
  onSearch: (query: string) => void;
}

export function SearchBar({ onSearch }: SearchBarProps) {
  const [query, setQuery] = useState("");

  return (
    <div className="search-bar">
      {/* VIOLATION FQV-02: Input has placeholder but no label or aria-label */}
      <input
        type="text"
        placeholder="Search products..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onKeyDown={(e) => e.key === "Enter" && onSearch(query)}
      />
      <button onClick={() => onSearch(query)}>Search</button>
    </div>
  );
}
