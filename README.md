# Decentralized Content Provenance System [truth_chain]

A blockchain-based solution for verifying the authenticity and origin of digital content using the Stacks blockchain.

Smart contract URL Deployed on testnet - https://explorer.hiro.so/txid/0xfbb882c008b7b31a894edca841129706db1639ebe6f56a40843570a28b3f518c?chain=testnet

## Overview

The Decentralized Content Provenance System allows content creators to register their digital content on the Stacks blockchain, providing an immutable record of ownership and authenticity. Consumers can verify the integrity of content and confirm its original creator, while platforms can integrate verification capabilities into their content management systems.

## Features

- **Content Registration**: Hash and register digital content (articles, images, videos) on the Stacks blockchain
- **Content Verification**: Verify the authenticity and integrity of published content
- **Creator Portfolios**: View all verified content from a specific creator
- **Content Revocation**: Allow creators to mark content as retracted or outdated
- **Platform Integration**: APIs and SDKs for content platforms to integrate verification capabilities

## User Workflows

### 1. Content Creator Workflow

#### Registration Process

1. **Content Creation**
   - Creator produces digital content (article, image, video, etc.)
   - Creator uploads content to the application

2. **Content Preparation**
   - System generates SHA-256 hash of the content
   - System displays the hash to the creator for confirmation
   - Creator connects their Stacks wallet to the application

3. **Signing & Registration**
   - Creator signs the content hash using their Stacks wallet
   - System prepares a transaction to call the `register-content` function
   - Creator approves transaction and pays Stacks gas fee
   - System submits transaction to the Stacks blockchain
   - Creator receives confirmation with verification ID once transaction is mined

4. **Content Publication**
   - Creator publishes content with attached verification link/badge
   - Verification link leads to a page showing blockchain proof of authenticity

#### Content Management

1. **View Published Content**
   - Creator logs into dashboard to see all registered content
   - Dashboard shows registration dates, verification status, and view counts

2. **Content Revocation**
   - Creator selects content from dashboard
   - Creator initiates revocation (calls `revoke-content` function)
   - Creator approves transaction and pays Stacks gas fee
   - Content remains on blockchain but is marked as inactive

### 2. Content Consumer Workflow

#### Content Verification

1. **Encountering Content**
   - Consumer sees content with a verification badge/link
   - Consumer clicks on verification badge to check authenticity

2. **Verification Process**
   - Verification page loads content and recalculates hash
   - System calls `verify-content` function with the calculated hash
   - System compares on-chain record with current content

3. **Verification Results**
   - If match: Consumer sees green verification badge showing:
     - Original author's Stacks address (with optional identity verification)
     - Registration timestamp
     - Content integrity status (unchanged)
   - If mismatch: Consumer sees warning that content has been modified
   - If revoked: Consumer sees notice that content has been retracted by creator

#### Author Verification

1. **Checking Creator's Portfolio**
   - Consumer can view all content by same creator
   - System calls `get-author-content` function with creator's address
   - Displays list of verified content from the same creator

### 3. Platform Integration Workflow

#### API Integration

1. **Setup Process**
   - Platform registers for API access
   - Platform integrates SDK into their CMS or content workflow

2. **Automated Registration**
   - When publishers create content on the platform:
     - Platform automatically hashes content
     - Platform requests signature from publisher's wallet
     - Platform calls `register-content` function
     - Platform attaches verification badge to published content

3. **Real-time Verification**
   - When content is viewed:
     - Platform automatically verifies content integrity
     - Platform displays verification status to readers
     - Platform warns of altered content

4. **Content Feed Filtering**
   - Platform can filter feeds to show only verified content
   - Platform can highlight verified creators
   - Platform displays verification stats in analytics

## Smart Contract Functions

The system relies on the following core smart contract functions:

- `register-content`: Records content hash, creator address, and timestamp
- `verify-content`: Checks if content hash exists and returns registration details
- `revoke-content`: Marks content as retracted by the original creator
- `get-author-content`: Retrieves all content registered by a specific creator

## Technical Implementation

- Built on the Stacks blockchain
- Content hashing using SHA-256
- Digital signatures using Stacks wallet
- Gas fees paid in Stacks cryptocurrency

## Simplified Flow

```
Content Creator → Upload Content → Generate Hash → Sign Hash → 
Call register-content → Transaction Confirmation → Receive Verification ID

Consumer → View Content → Check Verification → Calculate Hash → 
Call verify-content → Compare with Blockchain Record → Display Result

Consumer → View Creator Profile → Call get-author-content → 
Display All Verified Content → Validate Creator's History
```

## Getting Started

### Frontend Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/decentralized-content-provenance.git
   cd decentralized-content-provenance
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up Tailwind CSS**
   The project uses Tailwind CSS for styling. The configuration is already included in the project.
   ```bash
   # Tailwind CSS is already configured in the package.json
   # Just ensure the dependencies are installed
   npm install -D tailwindcss postcss autoprefixer
   ```

4. **Start the development server**
   ```bash
   npm run dev
   ```
   This will start the Vite development server. Navigate to `http://localhost:5173` to view the application.

5. **Build for production**
   ```bash
   npm run build
   ```
   This will generate optimized production files in the `dist` directory.

### Smart Contract Deployment

[Smart contract deployment instructions to be added]

## Documentation

[Links to detailed documentation to be added]

## License

MIT License

Copyright (c) 2025 Decentralized Content Provenance System

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contact

For questions, support, or collaboration:

- Email: [arowolokehinde231@gmail.com](mailto:arowolokehinde231@gmail.com)
- GitHub: [github.com/yourusername](https://github.com/yourusername)
- Discord: [Join our community](https://discord.gg/yourinvitelink)
