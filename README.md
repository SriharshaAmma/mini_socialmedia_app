## 📸 Mini SocialMedia App

A lightweight, real-time social platform built with Flutter & Supabase, featuring posts, likes, stories, chat, and user profiles — just like Instagram (Mini Version)! 🚀

### 🌟 Overview

Mini SocialMedia App is a modern, feature-rich mobile application where users can:

✔️ Create an account & login securely
✔️ Post photos with captions
✔️ View posts from other users (Feed)
✔️ Like, comment, and save posts
✔️ Follow/unfollow users
✔️ View real-time followers and following list
✔️ See public profiles and post counts
✔️ Record and view stories that disappear (24H concept)
✔️ Chat in real-time with other users
✔️ Edit profile — avatar, bio, username

All powered by Flutter, Supabase, Riverpod, and GoRouter.

### ⚙️ Core Features
#### 🔐 Authentication

Login & Register using email or username

Secure password authentication

Auto-login on app restart

#### 👤 User Profiles

Edit profile (Username, Bio, Profile Photo)

View any public profile

Follow/Unfollow functionality

Followers & Following list with profile data

Post count tracking

#### 📰 Feed (Home Screen)

View all posts in real-time feed

Like, comment, share, and save posts

Smooth UI with optimized images

Show user info attached to each post

#### ✍️ Create Post

Upload images from gallery

Write captions

Instantly updates feed

#### 💬 Real-Time Chat

One-to-one messaging

Live updates using Supabase Realtime

Seen status & timestamps

#### 🎭 Stories

Upload full-screen story

Display as Image with timestamp

Clickable story rings on feed

Auto-hide expired stories

### 🛠️ Tech Stack
Technology	Purpose
Flutter	Frontend UI framework
Supabase	Backend (Auth, DB, Storage)
Postgres	Database
GoRouter	Navigation & Routing
Riverpod	State Management
Supabase Storage	Profile & Post Image hosting
Share Plus	Post sharing
Dart	Core programming language

### 🔍 How It Works (Workflow Explanation)

#### 1️⃣ User Authentication
User signs up → Supabase creates account → Profile auto-saved in profiles table.

#### 2️⃣ Home Feed
Upon login → Fetches all posts with profile relation → Displays posts dynamically.

#### 3️⃣ Post Upload
User uploads image → Stored in Supabase Storage → Metadata stored in posts table.

#### 4️⃣ Follow System
When user follows someone → follows table stores follower_id & following_id.

#### 5️⃣ Followers/Following View
Uses manual join: First fetches IDs → retrieves profiles from profiles table.

#### 6️⃣ Chat & Stories
Supabase Subscriptions trigger real-time updates for messages and story entries.

### 🚀 Future Enhancements

🚩 Push notifications
🚩 Group chat / video calls
🚩 Dark Mode
🚩 Story auto-expiry
🚩 Explore Section (Top Posts & Trends)

### 🧪 Demo (Add When Ready)

🎥 Loom Demo: https://www.loom.com/share/b49e98c3668b404ea8ab727cd179fe6b

### 💡 Why This Project?

💬 “This app is a practical clone of Instagram basics using Flutter and Supabase.
It demonstrates user authentication, database relations, image hosting, chats, stories,
and a scalable mobile app architecture — perfect for learning & showcasing professional portfolio skills.”

### 👨‍💻 Author

Sri Harsha Amma
📧 Email: sriharshaamma5@gmail.com
🔗 GitHub: https://github.com/SriharshaAmma
