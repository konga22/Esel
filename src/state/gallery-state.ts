import { COLORS, DEMO_POSTS, type Post } from '../data/demo';

export type GalleryState = {
  selectedColorId: string | null;
  publishedPost: Post | null;
  likedIds: string[];
  savedIds: string[];
  profileName: string;
};

export type GalleryAction =
  | { type: 'choose-color'; colorId: string }
  | { type: 'publish'; post: Post }
  | { type: 'toggle-like'; postId: string }
  | { type: 'toggle-save'; postId: string }
  | { type: 'set-profile'; name: string }
  | { type: 'reset' };

export const initialGalleryState: GalleryState = {
  selectedColorId: null,
  publishedPost: null,
  likedIds: [],
  savedIds: [],
  profileName: '',
};

export function getVisiblePosts(
  state: GalleryState,
  mode: 'all' | 'same' | 'saved',
): Post[] {
  if (!COLORS.some((color) => color.id === state.selectedColorId)) return [];

  const posts = state.publishedPost
    ? [state.publishedPost, ...DEMO_POSTS]
    : DEMO_POSTS.filter((post) => post.colorId !== state.selectedColorId);

  if (mode === 'same') {
    return state.publishedPost
      ? posts.filter((post) => post.colorId === state.selectedColorId)
      : [];
  }

  if (mode === 'saved') {
    return posts.filter((post) => state.savedIds.includes(post.id));
  }

  return posts;
}

function toggleId(ids: string[], id: string): string[] {
  return ids.includes(id) ? ids.filter((item) => item !== id) : [...ids, id];
}

export function galleryReducer(state: GalleryState, action: GalleryAction): GalleryState {
  switch (action.type) {
    case 'choose-color': {
      if (
        state.publishedPost ||
        state.selectedColorId === action.colorId ||
        !COLORS.some((color) => color.id === action.colorId)
      ) return state;

      return { ...state, selectedColorId: action.colorId };
    }

    case 'publish': {
      const { post } = action;
      if (
        state.publishedPost ||
        !state.selectedColorId ||
        post.colorId !== state.selectedColorId ||
        !COLORS.some((color) => color.id === post.colorId) ||
        !post.id.trim() ||
        DEMO_POSTS.some((item) => item.id === post.id) ||
        !post.image.trim() ||
        !Number.isFinite(post.aspectRatio) ||
        post.aspectRatio <= 0 ||
        !Number.isFinite(post.likes) ||
        post.likes < 0
      ) return state;

      return { ...state, publishedPost: { ...post, own: true } };
    }

    case 'toggle-like':
    case 'toggle-save': {
      if (!getVisiblePosts(state, 'all').some((post) => post.id === action.postId)) {
        return state;
      }

      return action.type === 'toggle-like'
        ? { ...state, likedIds: toggleId(state.likedIds, action.postId) }
        : { ...state, savedIds: toggleId(state.savedIds, action.postId) };
    }

    case 'set-profile': {
      const profileName = action.name.trim();
      if (!profileName || profileName === state.profileName) return state;
      return { ...state, profileName };
    }

    case 'reset':
      return { ...initialGalleryState, likedIds: [], savedIds: [] };

    default:
      return state;
  }
}
