import assert from 'node:assert/strict';
import { test } from 'node:test';
import { COLORS, DEMO_POSTS, type Post } from '../src/data/demo';
import {
  galleryReducer,
  getVisiblePosts,
  initialGalleryState,
} from '../src/state/gallery-state';

const ownPost: Post = {
  id: 'my-outfit',
  author: '나',
  city: '서울',
  colorId: 'sage',
  image: 'file:///test/outfit.jpg',
  aspectRatio: 0.75,
  caption: '오늘의 기록',
  likes: 0,
};

function chooseSage() {
  return galleryReducer(initialGalleryState, { type: 'choose-color', colorId: 'sage' });
}

function publishSage() {
  return galleryReducer(chooseSage(), { type: 'publish', post: ownPost });
}

test('demo includes three posts for each of the three available colors', () => {
  assert.equal(COLORS.length, 3);
  assert.equal(DEMO_POSTS.length, 9);
  assert.equal(new Set(DEMO_POSTS.map((post) => post.id)).size, 9);
  for (const color of COLORS) {
    assert.equal(DEMO_POSTS.filter((post) => post.colorId === color.id).length, 3);
  }
});

test('all feed modes stay empty until a color is selected', () => {
  const state = { ...initialGalleryState, savedIds: ['sage-01', 'butter-01'] };
  for (const mode of ['all', 'same', 'saved'] as const) {
    assert.deepEqual(getVisiblePosts(state, mode), []);
  }
});

test('before publishing only other colors are visible and same-color feed stays locked', () => {
  const state = chooseSage();
  const posts = getVisiblePosts(state, 'all');
  assert.equal(posts.length, 6);
  assert.ok(posts.every((post) => post.colorId !== 'sage'));
  assert.deepEqual(getVisiblePosts(state, 'same'), []);
});

test('color can change before publication; invalid colors do not change state', () => {
  const state = chooseSage();
  const changed = galleryReducer(state, { type: 'choose-color', colorId: 'butter' });
  assert.equal(changed.selectedColorId, 'butter');
  assert.ok(getVisiblePosts(changed, 'all').every((post) => post.colorId !== 'butter'));
  assert.equal(galleryReducer(state, { type: 'choose-color', colorId: 'unknown' }), state);
  assert.equal(galleryReducer(state, { type: 'choose-color', colorId: 'sage' }), state);
});

test('a photo can only be published under its selected color', () => {
  assert.equal(
    galleryReducer(initialGalleryState, { type: 'publish', post: ownPost }),
    initialGalleryState,
  );
  const state = chooseSage();
  assert.equal(
    galleryReducer(state, { type: 'publish', post: { ...ownPost, colorId: 'butter' } }),
    state,
  );
});

test('publication preserves chosen color, unlocks same-color posts, and inserts own post once', () => {
  const state = publishSage();
  assert.equal(state.selectedColorId, 'sage');
  assert.equal(state.publishedPost?.own, true);
  assert.equal(getVisiblePosts(state, 'all').length, 10);
  assert.equal(getVisiblePosts(state, 'all')[0].id, ownPost.id);
  assert.equal(getVisiblePosts(state, 'same').length, 4);
  assert.ok(getVisiblePosts(state, 'same').every((post) => post.colorId === 'sage'));
  assert.equal(galleryReducer(state, { type: 'publish', post: ownPost }), state);
  assert.equal(
    galleryReducer(state, { type: 'publish', post: { ...ownPost, id: 'second-outfit' } }),
    state,
  );
  assert.equal(galleryReducer(state, { type: 'choose-color', colorId: 'butter' }), state);
});

test('publication rejects missing photos, invalid dimensions and duplicate demo identifiers', () => {
  const state = chooseSage();
  const invalidPosts = [
    { ...ownPost, id: '' },
    { ...ownPost, id: 'sage-01' },
    { ...ownPost, image: '  ' },
    { ...ownPost, aspectRatio: 0 },
    { ...ownPost, aspectRatio: Number.NaN },
    { ...ownPost, aspectRatio: Number.POSITIVE_INFINITY },
    { ...ownPost, likes: -1 },
  ];
  for (const post of invalidPosts) {
    assert.equal(galleryReducer(state, { type: 'publish', post }), state);
  }
});

test('likes and saves only toggle for visible, existing posts', () => {
  const state = chooseSage();
  for (const type of ['toggle-like', 'toggle-save'] as const) {
    for (const postId of ['sage-01', 'missing-post']) {
      assert.equal(galleryReducer(state, { type, postId }), state);
    }
    assert.equal(
      galleryReducer(initialGalleryState, { type, postId: 'butter-01' }),
      initialGalleryState,
    );
  }
  const liked = galleryReducer(state, { type: 'toggle-like', postId: 'butter-01' });
  assert.deepEqual(liked.likedIds, ['butter-01']);
  assert.deepEqual(
    galleryReducer(liked, { type: 'toggle-like', postId: 'butter-01' }).likedIds,
    [],
  );
  const saved = galleryReducer(state, { type: 'toggle-save', postId: 'butter-01' });
  assert.deepEqual(getVisiblePosts(saved, 'saved').map((post) => post.id), ['butter-01']);
  assert.deepEqual(
    galleryReducer(saved, { type: 'toggle-save', postId: 'butter-01' }).savedIds,
    [],
  );
});

test('changing colors cannot expose saved posts behind the current color gate', () => {
  const saved = galleryReducer(chooseSage(), { type: 'toggle-save', postId: 'butter-01' });
  const changed = galleryReducer(saved, { type: 'choose-color', colorId: 'butter' });
  assert.deepEqual(changed.savedIds, ['butter-01']);
  assert.deepEqual(getVisiblePosts(changed, 'saved'), []);

  const published = galleryReducer(changed, {
    type: 'publish',
    post: { ...ownPost, colorId: 'butter' },
  });
  assert.deepEqual(getVisiblePosts(published, 'saved').map((post) => post.id), ['butter-01']);
});

test('publishing makes same-color posts and own post available for reactions', () => {
  const state = publishSage();
  const liked = galleryReducer(state, { type: 'toggle-like', postId: 'sage-01' });
  assert.deepEqual(liked.likedIds, ['sage-01']);
  const saved = galleryReducer(liked, { type: 'toggle-save', postId: ownPost.id });
  assert.deepEqual(getVisiblePosts(saved, 'saved').map((post) => post.id), [ownPost.id]);
});

test('profile names are trimmed and blank submissions preserve the current name', () => {
  const state = galleryReducer(initialGalleryState, { type: 'set-profile', name: '  소라  ' });
  assert.equal(state.profileName, '소라');
  assert.equal(galleryReducer(state, { type: 'set-profile', name: '   ' }), state);
});

test('reset clears participation, reactions and profile without mutating prior state', () => {
  const published = publishSage();
  const liked = galleryReducer(published, { type: 'toggle-like', postId: 'sage-01' });
  const saved = galleryReducer(liked, { type: 'toggle-save', postId: 'butter-01' });
  const profile = galleryReducer(saved, { type: 'set-profile', name: '소라' });
  const reset = galleryReducer(profile, { type: 'reset' });

  assert.deepEqual(reset, initialGalleryState);
  assert.notEqual(reset.likedIds, initialGalleryState.likedIds);
  assert.notEqual(reset.savedIds, initialGalleryState.savedIds);
  assert.equal(profile.publishedPost?.id, ownPost.id);
  assert.deepEqual(profile.likedIds, ['sage-01']);
  assert.deepEqual(profile.savedIds, ['butter-01']);
  assert.deepEqual(initialGalleryState.likedIds, []);
  assert.deepEqual(initialGalleryState.savedIds, []);
  assert.equal(ownPost.own, undefined);
});
