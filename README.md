# Pantrify 🥣

**Pantrify** is a smart kitchen / pantry assistant app that helps users manage ingredients, get recipe suggestions, and interact with AI-powered features (e.g. classify ingredient units).  

---

## 🚀 Features

- Pantry / ingredient inventory management  
- AI-powered classification or detection (e.g. determining units)  
- Recipe lookup or suggestion (if implemented)  
- Management of ingredients (add, remove, update)  
- User authentication & profile (if applicable)  
- Integration with OpenAI APIs or other AI backends  

---

## 📁 Project Structure (example)

```plaintext
Pantrify/
├── Pantrify/ # Main app / modules
│ ├── IngredientAI.swift # AI helper for ingredients
│ ├── Models/
│ ├── Views/
│ └── Controllers/
├── Resources/ # Assets, images, configs
├── Tests/ # Unit / integration tests
├── .gitignore
├── README.md
└── … other project files (e.g. Info.plist, etc.)
```

---

## 🔧 Setup & Requirements

### Prerequisites

- Swift / iOS development environment (Xcode)  
- Access to OpenAI API (or whichever AI service you use)  
- Cocoapods / Swift Package Manager dependencies (if any)  

### Installation & Running Locally

1. Clone the repo:  
   ```bash
   git clone https://github.com/vinzhenryyy/Pantrify.git
   cd Pantrify
2. Open the Xcode project / workspace.
3. Ensure dependencies are installed (if using SPM, CocoaPods, etc.).
4. Set up environment variables / secrets (see below).
5. Build & run on simulator or device.

## 🔐 Environment & Secrets

The OpenAI API key and any sensitive credentials must **never** be committed to version control.

- Remove hard-coded keys from your source files  
- Use environment variables or configuration via Xcode schemes  
- Add your `.env`, config files, or secret files to `.gitignore`  

**Example in Swift:**

```swift
let OPENAI_API_KEY = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
```
In Xcode:

Go to your target → Edit Scheme → Run → Arguments / Environment Variables

Add OPENAI_API_KEY with your actual key (locally)

## 🛠 Usage & AI Endpoints

This app includes a function to detect measurement units for ingredients using OpenAI:
```swift
func detectUnitWithOpenAI(for ingredient: String, completion: @escaping (String) -> Void)
```

It sends a request to the OpenAI Chat Completion API with a prompt like:
```plaintext
“You are a food unit classifier. Respond only with ‘grams’, ‘liters’, or ‘pieces’.”
```
Depending on the result, it maps the response to one of those units (defaulting to “pieces” on error).

## ✅ Best Practices & Considerations
- Security: Never commit secrets. Use environment-based injection.
- Error Handling: Cover cases when API fails or returns unexpected output.
- Unit Tests: Write tests for your AI helper, mapping logic, and UI components.
- Rate Limiting / Quotas: If you use OpenAI or any API, guard against overuse.
- Caching: Cache responses where feasible to avoid repeated API calls.
- UI / UX: Provide inputs, loading states, and error messages to the user.

## 📄Contribution
Contributions are welcome — feel free to open issues or pull requests.

## 📝 Notes
- This project is currently under development.
- Always ensure no API keys or private credentials end up in commits.
- Clean history if sensitive data was ever committed (using git filter-repo, BFG, etc.).
