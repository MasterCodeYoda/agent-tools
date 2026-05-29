// Hero carousel — PLANTED VIOLATIONS for evolve scenario testing.

import { useEffect, useState } from "react";

const slides = [
  { title: "Welcome", image: "/hero-1.jpg" },
  { title: "Features", image: "/hero-2.jpg" },
  { title: "Pricing", image: "/hero-3.jpg" },
];

export function HeroCarousel() {
  const [current, setCurrent] = useState(0);

  // Auto-advance every 3 seconds
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrent((prev) => (prev + 1) % slides.length);
    }, 3000);
    return () => clearInterval(timer);
  }, []);

  return (
    // VIOLATION VDV-02: No prefers-reduced-motion respect
    // Animation runs unconditionally — users with vestibular disorders
    // cannot stop the auto-advancing carousel
    <div
      className="hero-carousel"
      style={{
        position: "relative",
        overflow: "hidden",
        height: "400px",
      }}
    >
      {slides.map((slide, i) => (
        <div
          key={slide.title}
          style={{
            position: "absolute",
            inset: 0,
            // CSS transition with no reduced-motion media query
            transition: "opacity 600ms ease-in-out",
            opacity: i === current ? 1 : 0,
          }}
        >
          <img src={slide.image} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          <h2 style={{ position: "absolute", bottom: "20px", left: "20px", color: "#fff" }}>
            {slide.title}
          </h2>
        </div>
      ))}
    </div>
  );
}
