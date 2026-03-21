// Zustand store stub for Dashboard scenario
import { create } from "zustand";

interface User {
  id: number;
  name: string;
  email: string;
  avatar: string;
  role: string;
}

interface UserStore {
  currentUser: User | null;
  setCurrentUser: (user: User) => void;
}

export const useUserStore = create<UserStore>((set) => ({
  currentUser: null,
  setCurrentUser: (user) => set({ currentUser: user }),
}));
