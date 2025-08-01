# 🏷️ Template Customization Guide

After cloning this template, replace these placeholders with your actual values:

## 📝 Find & Replace List

### Global Replacements
| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `{AppName}` | Your application name | "MyAwesomeApp" |
| `{YOUR_USERNAME}` | Your GitHub username | "john-doe" |
| `{YOUR_PROJECT_NAME}` | Your repository name | "my-awesome-app" |
| `{your-username}` | Your GitHub username (lowercase) | "john-doe" |
| `{your-repo-name}` | Your repository name (lowercase) | "my-awesome-app" |
| `{your-domain}` | Your company domain | "mycompany" |

### Files to Update

#### Required Updates
- [ ] `package.json` → name, description, repository URL
- [ ] `README.md` → all `{AppName}` and GitHub URLs
- [ ] `SETUP_GUIDE.md` → all `{AppName}` and GitHub URLs  
- [ ] `Supabase-API-Collection.json` → collection name and ID
- [ ] `SECURITY.md` → contact email domain

#### Optional Updates
- [ ] Modify `user_profiles` table schema in the migration file
- [ ] Add additional database tables/migrations
- [ ] Customize GitHub Actions workflow
- [ ] Generate TypeScript types after database setup

## 🔍 Quick Find & Replace Commands

### Using VS Code
1. Press `Ctrl+Shift+H` (or `Cmd+Shift+H` on Mac)
2. Enable "Replace in Files" mode
3. Use these find/replace pairs:

```
Find: {AppName}
Replace: YourAppName

Find: {YOUR_USERNAME}
Replace: your-github-username

Find: {YOUR_PROJECT_NAME}
Replace: your-repo-name
```

### Using Command Line
```bash
# Replace AppName
find . -type f -name "*.md" -o -name "*.json" | xargs sed -i 's/{AppName}/YourAppName/g'

# Replace GitHub usernames  
find . -type f -name "*.md" -o -name "*.json" | xargs sed -i 's/{YOUR_USERNAME}/your-github-username/g'

# Replace repo names
find . -type f -name "*.md" -o -name "*.json" | xargs sed -i 's/{YOUR_PROJECT_NAME}/your-repo-name/g'
```

## ✅ Verification Checklist

After customization, verify:
- [ ] All `{placeholder}` text is replaced
- [ ] GitHub URLs point to your repository
- [ ] Package.json has valid npm package name
- [ ] Postman collection has your app name
- [ ] Security contact email is updated
- [ ] Run `npm run status` to verify Supabase setup

## 💡 Pro Tips

1. **Keep it consistent**: Use the same naming convention across all files
2. **Valid npm names**: Package names must be lowercase, no spaces
3. **GitHub URLs**: Make sure all GitHub links point to your actual repository
4. **Backup first**: Consider creating a branch before mass replacements
5. **Test after**: Run `npm run dev` and `npm run status` to verify everything still works

---

**Ready to customize? Start with the find & replace commands above! 🚀**
