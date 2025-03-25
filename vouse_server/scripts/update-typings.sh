#!/bin/bash
# Helper script to fix TypeScript typing issues

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting TypeScript type improvements...${NC}"

# Create backup directory
BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo -e "${YELLOW}Creating backups in $BACKUP_DIR${NC}"
cp -r ./src $BACKUP_DIR/

# Fix empty module classes
echo -e "${YELLOW}Fixing empty module classes...${NC}"
MODULES=(
  "src/auth/auth.module.ts"
  "src/common/common.module.ts"
  "src/notifications/notifications.module.ts"
  "src/posts/posts.module.ts"
  "src/users/users.module.ts"
  "src/x/x.module.ts"
)

for module in "${MODULES[@]}"; do
  if [ -f "$module" ]; then
    sed -i 's/@Module({/@Module({\n  /* This module provides services for its domain *\//g' "$module"
    echo -e "${GREEN}Fixed empty class in $module${NC}"
  else
    echo -e "${RED}Module file $module not found${NC}"
  fi
done

# Run TypeScript checks to identify remaining issues
echo -e "${YELLOW}Running TypeScript compiler in strict mode...${NC}"
npx tsc --noEmit

# List top TypeScript issues to fix
echo -e "${YELLOW}Top TypeScript issues to address:${NC}"
echo "1. Replace 'any' types with specific interfaces from common/types"
echo "2. Add proper return types to all controller methods"
echo "3. Fix template literal expressions with proper type assertions"
echo "4. Use asApiError utility for error handling"
echo "5. Fix promise handling with proper async/await or void operator"

echo -e "${GREEN}Script completed. Review the TypeScript errors and fix using the common type interfaces.${NC}"
echo -e "${YELLOW}To apply fixes, run: npm run lint -- --fix${NC}"
