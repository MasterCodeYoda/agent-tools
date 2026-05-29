// Product listing page — qa:discover should generate CRUD specs
export function ProductsPage() {
  return (
    <div>
      <h1>Products</h1>
      <div className="filters">
        <select name="category">
          <option value="">All Categories</option>
          <option value="electronics">Electronics</option>
          <option value="clothing">Clothing</option>
        </select>
        <input type="search" placeholder="Search products..." />
      </div>
      <div className="product-grid">
        {/* Product cards rendered here */}
      </div>
      <nav className="pagination">
        <button>Previous</button>
        <span>Page 1 of 10</span>
        <button>Next</button>
      </nav>
    </div>
  );
}
