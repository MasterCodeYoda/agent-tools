// Modal component — PLANTED VIOLATIONS for evolve scenario testing.

import { useEffect, useState } from "react";

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}

export function Modal({ isOpen, onClose, children }: ModalProps) {
  const [isAnimating, setIsAnimating] = useState(false);

  // VIOLATION VDV-04: Non-interruptible animation
  // Close waits for transition to finish before unmounting
  // User cannot interact with content behind the modal during animation
  const handleClose = () => {
    setIsAnimating(true);
    setTimeout(() => {
      setIsAnimating(false);
      onClose(); // Only fires AFTER 400ms animation completes
    }, 400);
  };

  if (!isOpen && !isAnimating) return null;

  return (
    <div
      className="modal-overlay"
      onClick={handleClose}
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0,0,0,0.5)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        transition: "opacity 400ms",
        opacity: isAnimating ? 0 : 1,
      }}
    >
      {/* VIOLATION VDV-06: Wrong border-radius nesting
          Container: 16px radius, inner card: also 16px radius
          Should be: inner radius = outer radius - padding gap
          With 16px padding, inner should be 0px (16 - 16 = 0) */}
      <div
        className="modal-container"
        onClick={(e) => e.stopPropagation()}
        style={{
          backgroundColor: "#fff",
          borderRadius: "16px",
          padding: "16px",
          maxWidth: "500px",
          width: "100%",
        }}
      >
        <div
          className="modal-content"
          style={{
            backgroundColor: "#f5f5f5",
            borderRadius: "16px", // Should be 0px or close to it
            padding: "24px",
          }}
        >
          <button onClick={handleClose} style={{ float: "right" }}>
            Close
          </button>
          {children}
        </div>
      </div>
    </div>
  );
}
