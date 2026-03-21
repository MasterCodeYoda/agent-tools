// API routes — helps qa:discover understand available endpoints
export const routes = {
  auth: {
    login: "POST /api/auth/login",
    register: "POST /api/auth/register",
    logout: "POST /api/auth/logout",
    forgotPassword: "POST /api/auth/forgot-password",
  },
  products: {
    list: "GET /api/products",
    detail: "GET /api/products/:id",
    search: "GET /api/products/search",
  },
  cart: {
    get: "GET /api/cart",
    addItem: "POST /api/cart/items",
    updateItem: "PUT /api/cart/items/:id",
    removeItem: "DELETE /api/cart/items/:id",
  },
  orders: {
    create: "POST /api/orders",
    list: "GET /api/orders",
    detail: "GET /api/orders/:id",
  },
};
