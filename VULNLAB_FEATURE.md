# VulnLab Active Directory Labs Listing Feature

## Overview
This feature adds comprehensive support for listing and browsing Active Directory (AD) labs from the VulnLab penetration testing platform integrated directly into the Hackossem Flask application.

## Components Implemented

### 1. **VulnLabClient** (Backend)
A Python client class that handles communication with VulnLab's API:

#### Features:
- **Real API Support**: Connects to `https://api.vulnlab.com` using Bearer token authentication
- **Fallback Mock Data**: Automatically serves mock data when API key is unavailable
- **Error Handling**: Gracefully falls back to mock data if API calls fail
- **Standardized Format**: Normalizes API responses into a consistent data structure

#### Configuration:
- API key: Set via `VULNLAB_API_KEY` environment variable
- If not set, mock data is used automatically

#### Methods:
- `get_ad_labs()`: Fetch all AD labs with fallback support
- `_parse_labs()`: Parse and normalize API responses
- `_get_mock_ad_labs()`: Provide demonstration data

### 2. **REST API Endpoint** (`/api/vulnlab/ad-labs`)
A JSON API endpoint that serves AD labs with integrated filtering:

#### Query Parameters:
- `difficulty`: Filter by difficulty level (Easy, Medium, Hard)
- `search`: Full-text search across lab names and descriptions

#### Response Format:
```json
{
  "total": 5,
  "labs": [
    {
      "id": "ad-lab-1",
      "name": "Active Directory Basics",
      "description": "Learn fundamental AD concepts...",
      "difficulty": "Easy",
      "category": "active-directory",
      "machines": ["DC-1", "CLIENT-1"],
      "tags": ["AD", "Windows", "Beginner"],
      "url": "https://vulnlab.com/labs/ad-basics"
    }
    ...
  ]
}
```

#### Features:
- Uses **MagicQuery** for flexible, chainable filtering
- Supports multiple simultaneous filters
- Returns result count and full lab details

### 3. **Web UI** (`/vulnlab-ad-labs`)
A beautiful, responsive Angular-based interface for browsing AD labs:

#### Features:
- **Responsive Grid Layout**: Auto-adjusting card layout for all screen sizes
- **Live Search**: Real-time filtering across lab names and descriptions
- **Difficulty Filter**: Dropdown to filter by Easy/Medium/Hard
- **Lab Cards**: Display comprehensive information for each lab:
  - Lab name and description
  - Difficulty badge (color-coded)
  - Associated tags
  - Required machines/systems
  - Link to launch lab on VulnLab

#### Design:
- Modern gradient background (purple theme)
- Smooth animations and transitions
- Accessible color scheme with clear visual hierarchy
- Statistics panel showing filtered results count
- Navigation breadcrumbs to other demo pages

#### Technologies:
- AngularJS 1.8.2 for reactive UI
- CSS3 for styling and animations
- Responsive flexbox and grid layouts

### 4. **Mock Data** (Demo Labs)
Five comprehensive AD lab examples demonstrating various security concepts:

1. **Active Directory Basics** (Easy)
   - Machines: DC-1, CLIENT-1
   - Tags: AD, Windows, Beginner
   - Learn fundamental AD concepts

2. **LDAP Enumeration & Exploitation** (Medium)
   - Machines: DC-1, CLIENT-1, CLIENT-2
   - Tags: LDAP, Enumeration, AD, Exploitation
   - Master LDAP protocol exploitation

3. **Kerberos & ASREProast** (Medium)
   - Machines: DC-1, CLIENT-1
   - Tags: Kerberos, ASREProast, AD, Attacks
   - Understand Kerberos and ASREProast attacks

4. **Privilege Escalation in AD** (Hard)
   - Machines: DC-1, CLIENT-1, CLIENT-2, SERVER-1
   - Tags: Privilege Escalation, AD, Post-Exploitation
   - Exploit common privilege escalation vectors

5. **Golden Ticket & Domain Takeover** (Hard)
   - Machines: DC-1, CLIENT-1, CLIENT-2
   - Tags: Golden Ticket, PTH, Domain Control, AD
   - Learn domain takeover techniques

## Routes Added

| Route | Method | Description |
|-------|--------|-------------|
| `/vulnlab-ad-labs` | GET | Serve the AD labs UI |
| `/api/vulnlab/ad-labs` | GET | API endpoint for labs data |
| `/` | GET | Updated home page with VulnLab link |

## Dependencies

New dependencies added to `requirements.txt`:
- `Flask==2.3.3` - Web framework
- `requests==2.31.0` - HTTP client for API calls
- `wasmer==1.1.0` - WebAssembly runtime (existing)
- `wasmer_compiler_cranelift==1.1.0` - WASM compiler (existing)

## Usage Examples

### Fetch All Labs:
```bash
curl http://localhost:5000/api/vulnlab/ad-labs
```

### Filter by Difficulty:
```bash
curl "http://localhost:5000/api/vulnlab/ad-labs?difficulty=Medium"
```

### Search Labs:
```bash
curl "http://localhost:5000/api/vulnlab/ad-labs?search=Kerberos"
```

### Combined Filters:
```bash
curl "http://localhost:5000/api/vulnlab/ad-labs?difficulty=Hard&search=Privilege"
```

## Environment Configuration

To use the real VulnLab API:
```bash
export VULNLAB_API_KEY="your-api-key-here"
python app.py
```

If `VULNLAB_API_KEY` is not set, the application automatically uses mock data.

## Integration with Existing Features

The feature integrates seamlessly with:
- **MagicQuery**: Uses the LINQ-style query engine for filtering
- **AngularJS Architecture**: Follows existing app's frontend patterns
- **Flask Routes**: Follows existing route structure and conventions
- **UI Theme**: Matches the modern gradient design of other demo pages

## Testing

All components have been tested:
- ✅ VulnLab API client initialization
- ✅ Mock data retrieval (5 labs)
- ✅ Difficulty level filtering
- ✅ Search/keyword filtering
- ✅ Combined filter operations
- ✅ UI page rendering
- ✅ Angular bindings
- ✅ Responsive design

## Files Modified

1. `app.py` - Added VulnLabClient, API endpoint, UI, and routing
2. `requirements.txt` - Added requests dependency

## Future Enhancements

Potential improvements for future versions:
1. Lab progress tracking (user completion status)
2. Lab ratings and reviews
3. Lab recommendations based on difficulty progression
4. Integration with user authentication
5. Export/import lab configurations
6. Custom lab creation interface
7. Lab completion badges and achievements
8. Advanced filtering (by tags, machines, prerequisites)
9. Lab completion time estimates
10. Automated lab provisioning API

## Commit Information

- **Branch**: `claude/vulnlab-list-ad-labs-pgchvl`
- **Commits**:
  1. Initial feature implementation with VulnLabClient, API endpoint, and UI
  2. Fixed Jinja2 template rendering for Angular expressions
