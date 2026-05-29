// Product card component — PLANTED VIOLATIONS for evolve scenario testing.

interface Product {
  id: number;
  name: string;
  price: number;
  imageUrl: string;
  description: string;
}

interface ProductCardProps {
  product: Product;
}

export function ProductCard({ product }: ProductCardProps) {
  return (
    <div className="product-card">
      {/* VIOLATION FQV-01: Image missing alt text */}
      <img src={product.imageUrl} />

      <h3>{product.name}</h3>

      {/* VIOLATION FQV-07: Light gray on white — fails WCAG contrast (2.32:1) */}
      <p style={{ color: "#aaa", backgroundColor: "#fff" }}>
        {product.description}
      </p>

      <span className="price">${product.price.toFixed(2)}</span>
    </div>
  );
}
