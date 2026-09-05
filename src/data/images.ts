import { Asset } from 'expo-asset';
import type { Post } from './demo';

const images: Record<string, number> = {
  'sage-01': require('../../assets/demo/green-blouse.jpg'),
  'sage-02': require('../../assets/demo/green-skirt.jpg'),
  'sage-03': require('../../assets/demo/green-blouse.jpg'),
  'butter-01': require('../../assets/demo/yellow-street.jpg'),
  'butter-02': require('../../assets/demo/beige-blazer.jpg'),
  'butter-03': require('../../assets/demo/yellow-dress.jpg'),
  'powder-blue-01': require('../../assets/demo/blue-city.jpg'),
  'powder-blue-02': require('../../assets/demo/blue-outfit.jpg'),
  'powder-blue-03': require('../../assets/demo/blue-outfit.jpg'),
};

export function postImage(post: Post): number | { uri: string } {
  return post.own ? { uri: post.image } : (images[post.id] ?? { uri: post.image });
}

export function sampleImage(colorId: string): string {
  return Asset.fromModule(images[`${colorId}-01`]).uri;
}
