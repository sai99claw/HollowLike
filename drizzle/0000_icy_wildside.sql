CREATE TABLE `player_feedback` (
	`id` text PRIMARY KEY NOT NULL,
	`nickname` text NOT NULL,
	`category` text NOT NULL,
	`message` text NOT NULL,
	`version` text NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `feedback_created_at` ON `player_feedback` (`created_at`);