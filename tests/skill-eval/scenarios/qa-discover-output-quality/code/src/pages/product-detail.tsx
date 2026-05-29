// Product detail page with add-to-cart
export function ProductDetailPage() {
  return (
    <div>
      <nav className="breadcrumb">
        <a href="/products">Products</a> / <span>Product Name</span>
      </nav>
      <div className="product-detail">
        <img src="/product.jpg" alt="Product name" />
        <div>
          <h1>Product Name</h1>
          <p className="price">$29.99</p>
          <p className="description">Product description here.</p>
          <div className="quantity">
            <label htmlFor="qty">Quantity</label>
            <input id="qty" type="number" min="1" max="99" defaultValue={1} />
          </div>
          <button className="add-to-cart">Add to Cart</button>
        </div>
      </div>
      <section className="reviews">
        <h2>Customer Reviews</h2>
        {/* Reviews rendered here */}
      </section>
    </div>
  );
}
