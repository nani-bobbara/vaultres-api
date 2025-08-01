# 🚀 {AppName} - Supabase Starter Template

**A production-ready Supabase project template with secure user authentication and profiles.**

> ⭐ **Use this template**: Click "Use this template" button above to create your own repository

## 🎯 What's Included

- 🔐 **Secure Authentication**: Complete auth flow with Supabase Auth
- 👤 **User Profiles**: Auto-created profiles with RLS security
- � **File Storage**: Secure avatar and document storage with policies
- ⚡ **Edge Functions**: Serverless functions for custom business logic
- 🔄 **Realtime**: Live data sync with websocket connections
- 📝 **Posts System**: Example content system with realtime updates
- �🛡️ **Production Security**: Row Level Security, input validation, constraints
- 🔄 **CI/CD Pipeline**: Automated testing and deployment with GitHub Actions
- 🧪 **API Testing**: Complete Postman collection with security tests
- 📚 **TypeScript Ready**: Auto-generated database types
- 🏗️ **Best Practices**: Domain-driven, event-driven, test-driven design

## 📦 Core Components

### Database Schema
- **user_profiles** - User profile data with RLS
- **posts** - Example content with realtime capabilities
- **Storage buckets** - Avatars (public) and documents (private)

### Edge Functions
- **hello-world** - Basic serverless function example
- **user-avatar** - Avatar upload with automatic profile updates

### API Testing
- **Postman Collection** - Complete test suite for all endpoints including:
  - Authentication flows
  - User profile management
  - Posts with realtime capabilities
  - File storage operations
  - Edge function calls
  - Security boundary testing

## ⚡ Quick Start

### 1. Use This Template
```bash
# Click "Use this template" on GitHub, then:
git clone https://github.com/{YOUR_USERNAME}/{YOUR_PROJECT_NAME}.git
cd {YOUR_PROJECT_NAME}
```

### 2. Customize Your App
```bash
# Replace template placeholders with your app details
# See docs/CUSTOMIZATION.md for complete instructions

# Quick replacements:
# {AppName} → YourAppName
# {YOUR_USERNAME} → your-github-username  
# {YOUR_PROJECT_NAME} → your-repo-name
```

### 3. Start Development
```bash
# Copy environment template (works with defaults)
cp .env.example .env.local

# Start local Supabase (requires Docker)
supabase start

# Apply database migrations
supabase db reset

# Generate TypeScript types
npm run types
```

### 4. Deploy to Production
```bash
# Add GitHub secrets (see Production Setup below)
git push origin main
```

## 🗃️ Database Schema

### `user_profiles` Table
```sql
id          uuid PRIMARY KEY → auth.users(id)
username    text UNIQUE NOT NULL
full_name   text
avatar_url  text
created_at  timestamptz DEFAULT now()
updated_at  timestamptz DEFAULT now()
```

**Security Features:**
- ✅ Row Level Security (RLS) enabled
- ✅ Users can only access their own profiles  
- ✅ Auto-creation via database triggers
- ✅ Input validation and constraints
- ✅ Performance indexes

## 🚀 Migration Best Practices

### Safe Migration Guidelines

1. **Always test locally first**:
   ```bash
   npm run reset  # Reset local DB
   npm run test   # Run test suite
   ```

2. **Check differences before deploying**:
   ```bash
   npm run diff   # See what will change
   ```

3. **Use migration naming convention**:
   - Format: `YYYYMMDDHHMMSS_descriptive_name.sql`
   - Example: `20250101120000_add_user_preferences_table.sql`

4. **Never edit existing migrations** - Always create new ones

5. **Include rollback strategy** in your migration planning

### Common Migration Patterns

```sql
-- ✅ Safe: Adding nullable column
ALTER TABLE users ADD COLUMN phone TEXT;

-- ✅ Safe: Adding index
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- ⚠️  Careful: Adding NOT NULL column (needs default or backfill)
ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'active';

-- ❌ Dangerous: Dropping columns (data loss)
-- ALTER TABLE users DROP COLUMN old_field;
```

### Local Development
```bash
cp .env.example .env.local  # No configuration needed
supabase start              # Get keys from 'supabase status'
```

### Production Deployment

1. **Create Supabase Project**: [supabase.com](https://supabase.com) → "New Project"

2. **Add GitHub Secrets** (Settings → Secrets and variables → Actions):
   ```
   SUPABASE_ACCESS_TOKEN = your-personal-access-token
   SUPABASE_PROJECT_ID = your-project-reference-id  
   SUPABASE_DB_PASSWORD = your-database-password
   ```

3. **Deploy**: `git push origin main`

## 🚀 Migration Best Practices

Import `Supabase-API-Collection.json` into Postman. Tests include:
- ✅ User registration and authentication
- ✅ Profile CRUD operations
- ✅ Security boundary testing
- ✅ Input validation rules

## 🔧 Available Scripts

```bash
npm run dev                  # Start local Supabase
npm run build               # Deploy to production  
npm run reset               # Reset local database
npm run types               # Generate TypeScript types
npm run diff                # Check migration differences
npm run functions:serve     # Serve Edge Functions locally
npm run functions:deploy    # Deploy all Edge Functions
npm run functions:deploy:hello   # Deploy hello-world function
npm run functions:deploy:avatar  # Deploy user-avatar function
npm run status              # Check Supabase status
npm run stop                # Stop local Supabase
```

## 🏗️ Project Structure

```
├── .github/workflows/       # GitHub Actions CI/CD
├── supabase/               # Supabase configuration
│   ├── config.toml        # Local development settings
│   ├── seed.sql           # Sample data
│   ├── migrations/        # Database schema & migrations
│   └── functions/         # Edge Functions
│       ├── hello-world/   # Basic serverless function
│       └── user-avatar/   # Avatar upload function
├── types/                 # TypeScript database types (auto-generated)
├── docs/                  # Documentation
└── package.json          # NPM scripts & dependencies
```

### TypeScript Database Types

The `types/` directory contains auto-generated TypeScript types for your Supabase database:

```bash
# Generate types from your actual database schema
npm run types
```

**Important Notes:**
- Never edit `database.types.ts` manually - it's auto-generated
- Re-run `npm run types` after any database schema changes
- This file is ignored in git by default (generated on each machine)

**Usage Example:**
```typescript
import { Database } from './types/database.types'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

// Now you get full TypeScript intellisense!
const { data: profiles } = await supabase
  .from('user_profiles')  // ✅ Autocompleted
  .select('*')           // ✅ Type-safe
```

## 🔧 Customization

### Frontend Integration Example
```typescript
import { createClient } from '@supabase/supabase-js'
import { Database } from './types/database.types'

const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

// Type-safe database operations
const { data: profile } = await supabase
  .from('user_profiles')
  .select('*')
  .eq('id', user.id)
  .single()
```

### Adding New Tables
1. `supabase migration new add_your_table`
2. Add RLS policies for security
3. `npm run types` to generate new types
4. Update Postman collection

## 📚 Documentation & Resources

- 📋 [Customization Guide](docs/CUSTOMIZATION.md) - How to adapt this template for your project
- 📖 [Supabase Documentation](https://supabase.com/docs)
- 🎓 [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- 🔐 [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- 🚀 [Deployment Guide](https://supabase.com/docs/guides/getting-started/local-development)

## 🤝 Contributing

1. Fork this repository
2. Create your feature branch
3. Test thoroughly
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**🌟 Star this repository if it helped you!**

Made with ❤️ for the Supabase community
