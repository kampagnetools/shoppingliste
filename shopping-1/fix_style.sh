#!/bin/bash

# Fix all Vue files - remove rounded corners and gradients
for file in $(find . -name "*.vue" -type f); do
  # Remove rounded classes (keep rounded-md for labels only)
  sed -i 's/ rounded-lg//g; s/ rounded-2xl//g; s/ rounded-xl//g; s/ rounded-full//g' "$file"
  
  # Replace gradients with flat colors
  sed -i 's/bg-gradient-to-r from-indigo-600 to-indigo-700/bg-indigo-600/g' "$file"
  sed -i 's/hover:from-indigo-700 hover:to-indigo-800/hover:bg-indigo-700/g' "$file"
  sed -i 's/bg-gradient-to-r from-emerald-600 to-emerald-700/bg-emerald-600/g' "$file"
  sed -i 's/hover:from-emerald-700 hover:to-emerald-800/hover:bg-emerald-700/g' "$file"
  sed -i 's/bg-gradient-to-r from-slate-50 to-white/bg-white/g' "$file"
  sed -i 's/bg-gradient-to-b from-slate-800 to-slate-900/bg-slate-800/g' "$file"
  sed -i 's/ active:scale-95//g' "$file"
  sed -i 's/ shadow-md//g; s/ shadow-sm//g; s/ shadow-2xl//g; s/ shadow-xl//g' "$file"
done

echo "Style cleanup complete!"
