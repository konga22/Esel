export type ColorTheme = {
  id: string;
  name: string;
  englishName: string;
  hex: string;
  description: string;
};

export type Post = {
  id: string;
  author: string;
  city: string;
  colorId: string;
  image: string;
  aspectRatio: number;
  caption: string;
  likes: number;
  own?: boolean;
};

export const COLORS: ColorTheme[] = [
  {
    id: 'sage',
    name: '세이지',
    englishName: 'Sage',
    hex: '#A8B5A0',
    description: '차분한 초록으로, 오늘을 조금 느긋하게.',
  },
  {
    id: 'butter',
    name: '버터',
    englishName: 'Butter',
    hex: '#E5C982',
    description: '부드러운 노랑 한 조각을 더해보세요.',
  },
  {
    id: 'powder-blue',
    name: '파우더 블루',
    englishName: 'Powder blue',
    hex: '#9BB8CF',
    description: '맑은 하늘을 닮은 작은 포인트.',
  },
];

export const DEMO_POSTS: Post[] = [
  {
    id: 'sage-01',
    author: 'sora',
    city: '서울',
    colorId: 'sage',
    image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.8,
    caption: '익숙한 옷에 오늘의 색 한 조각.',
    likes: 28,
  },
  {
    id: 'butter-01',
    author: 'elle',
    city: '파리',
    colorId: 'butter',
    image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.72,
    caption: '햇살 좋은 날, 가벼운 발걸음.',
    likes: 42,
  },
  {
    id: 'powder-blue-01',
    author: 'haru',
    city: '도쿄',
    colorId: 'powder-blue',
    image: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.75,
    caption: '산책을 조금 더 하고 싶은 날.',
    likes: 36,
  },
  {
    id: 'sage-02',
    author: 'june',
    city: '코펜하겐',
    colorId: 'sage',
    image: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.88,
    caption: '좋아하는 질감들을 함께.',
    likes: 19,
  },
  {
    id: 'butter-02',
    author: 'nari',
    city: '서울',
    colorId: 'butter',
    image: 'https://images.unsplash.com/photo-1551232864-3f0890e580d9?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.78,
    caption: '작은 색이 바꾸는 하루의 기분.',
    likes: 31,
  },
  {
    id: 'powder-blue-02',
    author: 'olivia',
    city: '런던',
    colorId: 'powder-blue',
    image: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.7,
    caption: '자주 입는 데님도 오늘은 새롭게.',
    likes: 57,
  },
  {
    id: 'sage-03',
    author: 'mia',
    city: '멜버른',
    colorId: 'sage',
    image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.83,
    caption: '옷장 안에서 찾은 오늘의 초록.',
    likes: 24,
  },
  {
    id: 'butter-03',
    author: 'lena',
    city: '베를린',
    colorId: 'butter',
    image: 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.74,
    caption: '아무 계획 없는 오후의 옷차림.',
    likes: 45,
  },
  {
    id: 'powder-blue-03',
    author: 'yuna',
    city: '부산',
    colorId: 'powder-blue',
    image: 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=900&q=85',
    aspectRatio: 0.86,
    caption: '오늘의 하늘과 비슷한 마음으로.',
    likes: 33,
  },
];
