import React, { createContext, use, useEffect, useReducer, useRef, useState } from 'react';
import { galleryReducer, initialGalleryState } from './gallery-state';
import type { GalleryAction, GalleryState } from './gallery-state';

type GalleryContextValue = {
  state: GalleryState;
  dispatch: React.Dispatch<GalleryAction>;
  notice: string;
  notify: (message: string) => void;
};

const GalleryContext = createContext<GalleryContextValue | null>(null);

export function GalleryProvider({ children }: React.PropsWithChildren) {
  const [state, dispatch] = useReducer(galleryReducer, initialGalleryState);
  const [notice, setNotice] = useState('');
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => { if (timer.current) clearTimeout(timer.current); }, []);
  function notify(message: string) {
    if (timer.current) clearTimeout(timer.current);
    setNotice(message);
    timer.current = setTimeout(() => setNotice(''), 4000);
  }
  return <GalleryContext value={{ state, dispatch, notice, notify }}>{children}</GalleryContext>;
}

export function useGallery() {
  const context = use(GalleryContext);
  if (!context) throw new Error('GalleryProvider is required');
  return context;
}
