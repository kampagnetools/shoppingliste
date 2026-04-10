#!/bin/bash

# Remove rounded-lg, rounded-2xl, rounded-xl, rounded-full, rounded-xl from all files
find . -name "*.vue" -type f -exec sed -i 's/ rounded-lg//g; s/ rounded-2xl//g; s/ rounded-xl//g; s/ rounded-full/ /g; s/ rounded-md/ rounded-md/g' {} +

# Replace gradient buttons with flat colors
sed -i 's/bg-gradient-to-r from-indigo-600 to-indigo-700/bg-indigo-600/g' App.vue
sed -i 's/hover:from-indigo-700 hover:to-indigo-800/hover:bg-indigo-700/g' App.vue
sed -i 's/bg-gradient-to-r from-emerald-600 to-emerald-700/bg-emerald-600/g' App.vue
sed -i 's/hover:from-emerald-700 hover:to-emerald-800/hover:bg-emerald-700/g' App.vue
sed -i 's/bg-gradient-to-r from-slate-50 to-white/bg-white/g' App.vue
sed -i 's/bg-gradient-to-b from-slate-800 to-slate-900/bg-slate-800/g' App.vue
sed -i 's/bg-gradient-to-r from-slate-50 to-white/bg-white/g' App.vue

echo "Done!"
