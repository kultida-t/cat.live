import { MOCK_POSTS, FEED_USERS } from '@/data/mock-feed';
import type { FeedTab, FeedUser, Post } from '@/types/feed';

/**
 * ชั้นบริการฟีด — หน้าจอเรียกผ่าน interface นี้เท่านั้น
 * ช่วงนี้ใช้ข้อมูล mock ในเครื่อง; ตอนต่อ API จริง (NestJS) ให้สร้าง
 * implementation ใหม่ที่คืนรูปแบบเดียวกัน โดยไม่แก้หน้าจอ
 */

export interface FeedQuery {
  tab: FeedTab;
  category?: string;
  cursor?: number;
  limit?: number;
}

export interface FeedPage {
  posts: Post[];
  nextCursor?: number;
}

export interface FeedService {
  fetchPosts(query: FeedQuery): Promise<FeedPage>;
  fetchStoryUsers(): Promise<FeedUser[]>;
  toggleLike(postId: string): Promise<Post>;
  toggleSave(postId: string): Promise<Post>;
  toggleFollow(userId: string): Promise<Post[]>;
  hidePost(postId: string): Promise<void>;
  reportPost(postId: string, reason: string): Promise<void>;
  deletePost(postId: string): Promise<void>;
}

const PAGE_SIZE = 5;
const MOCK_LATENCY_MS = 400;

const delay = () => new Promise((r) => setTimeout(r, MOCK_LATENCY_MS));

class MockFeedService implements FeedService {
  private posts: Post[] = MOCK_POSTS.map((p) => ({ ...p }));
  private hiddenIds = new Set<string>();

  async fetchPosts({ tab, category, cursor = 0, limit = PAGE_SIZE }: FeedQuery): Promise<FeedPage> {
    await delay();
    let list = this.posts.filter((p) => !this.hiddenIds.has(p.id));
    if (tab === 'following') list = list.filter((p) => p.isFollowingAuthor);
    if (tab === 'saved') list = list.filter((p) => p.isSaved);
    if (category && category !== 'ทั้งหมด') list = list.filter((p) => p.category === category);

    const page = list.slice(cursor, cursor + limit);
    const nextCursor = cursor + limit < list.length ? cursor + limit : undefined;
    return { posts: page, nextCursor };
  }

  async fetchStoryUsers(): Promise<FeedUser[]> {
    await delay();
    return FEED_USERS.filter((u) =>
      this.posts.some((p) => p.author.id === u.id && p.isFollowingAuthor),
    );
  }

  async toggleLike(postId: string): Promise<Post> {
    await delay();
    const post = this.mustFind(postId);
    post.isLiked = !post.isLiked;
    post.likeCount += post.isLiked ? 1 : -1;
    return { ...post };
  }

  async toggleSave(postId: string): Promise<Post> {
    await delay();
    const post = this.mustFind(postId);
    post.isSaved = !post.isSaved;
    return { ...post };
  }

  async toggleFollow(userId: string): Promise<Post[]> {
    await delay();
    this.posts = this.posts.map((p) =>
      p.author.id === userId ? { ...p, isFollowingAuthor: !p.isFollowingAuthor } : p,
    );
    return [...this.posts];
  }

  async hidePost(postId: string): Promise<void> {
    await delay();
    this.hiddenIds.add(postId);
  }

  async reportPost(_postId: string, _reason: string): Promise<void> {
    await delay();
  }

  async deletePost(postId: string): Promise<void> {
    await delay();
    this.posts = this.posts.filter((p) => p.id !== postId);
  }

  private mustFind(postId: string): Post {
    const post = this.posts.find((p) => p.id === postId);
    if (!post) throw new Error(`ไม่พบโพสต์ ${postId}`);
    return post;
  }
}

export const feedService: FeedService = new MockFeedService();
