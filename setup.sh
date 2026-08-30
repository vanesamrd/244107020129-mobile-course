#!/bin/bash

weeks=(
"01-week-1-mobile-development-ecosystem-flutter-refresh"
"02-week-2-declarative-ui-responsive-design"
"03-week-3-navigation-state-management"
"04-week-4-networking-rest-api"
"05-week-5-local-storage-offline-first"
"06-week-6-authentication-security-fcm"
"07-week-7-clean-architecture"
)

for w in "${weeks[@]}"; do
  mkdir -p "$w"/{lib,test,screenshots}
  echo "# ${w}" > "$w/README.md"
done

week8_15=(
"08-week-8-mid-project-review:docs"
"09-week-9-ai-assisted-development:lib,docs"
"10-week-10-ai-feature-integration:lib,docs"
"11-week-11-performance-optimization:lib,docs"
"12-week-12-testing-quality-assurance:test,coverage"
"13-week-13-ci-cd-automation:.github,workflows"
"14-week-14-deployment-monitoring:docs"
"15-week-15-secure-mobile-development:docs"
)

for entry in "${week8_15[@]}"; do
  name="${entry%%:*}"
  dirs="${entry##*:}"
  IFS=',' read -ra arr <<< "$dirs"
  for d in "${arr[@]}"; do
    mkdir -p "$name/$d"
  done
  mkdir -p "$name/screenshots"
  echo "# ${name}" > "$name/README.md"
done

mkdir -p "16-week-16-final-project-expo"/{lib,docs,screenshots,demo-video}
echo "# 16-week-16-final-project-expo" > "16-week-16-final-project-expo/README.md"

mkdir -p notes/{reflections,learning-journal,resources}
echo "# Portfolio Summary" > portfolio-summary.md

find . -type d -empty -exec touch {}/.gitkeep \;

echo "Selesai! Struktur folder udah dibuat."
