import {sqliteTable,text,index} from 'drizzle-orm/sqlite-core';
export const feedback=sqliteTable('player_feedback',{id:text('id').primaryKey(),nickname:text('nickname').notNull(),category:text('category').notNull(),message:text('message').notNull(),version:text('version').notNull(),createdAt:text('created_at').notNull()},t=>[index('feedback_created_at').on(t.createdAt)]);
