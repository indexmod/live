#!/bin/bash
# === Очистка репозитория от mp3/mp4 и сжатие истории ===

set -e  # Остановиться при любой ошибке

echo "🔍 Проверяем, установлен ли git-filter-repo..."
if ! command -v git-filter-repo &> /dev/null
then
    echo "Устанавливаем git-filter-repo..."
    if command -v pip3 &> /dev/null; then
        pip3 install --user git-filter-repo
    elif command -v brew &> /dev/null; then
        brew install git-filter-repo
    else
        echo "⚠️ Не удалось установить git-filter-repo — установи вручную с помощью 'pip3 install --user git-filter-repo'"
        exit 1
    fi
fi

# 1. Создаём временную папку
echo "📁 Создаю временную папку tmp_big..."
mkdir -p tmp_big

# 2. Переносим большие файлы
echo "📦 Перемещаю mp3/mp4 в tmp_big..."
find . -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.mp4" \) -exec mv {} tmp_big/ \; || true

# 3. Добавляем в .gitignore
echo "📝 Обновляю .gitignore..."
if ! grep -q "*.mp3" .gitignore 2>/dev/null; then
    echo -e "\n# Игнорируем большие медиафайлы\n*.mp3\n*.mp4" >> .gitignore
fi

# 4. Удаляем из индекса
echo "❌ Удаляю mp3/mp4 из индекса..."
git rm --cached *.mp3 *.mp4 2>/dev/null || true

# 5. Коммитим изменения
echo "💾 Создаю коммит..."
git add .gitignore
git commit -m "Очистил репозиторий от mp3/mp4 и добавил в .gitignore" || true

# 6. Очищаем историю
echo "🧹 Запускаю git-filter-repo..."
git filter-repo --path-glob '*.mp3' --path-glob '*.mp4' --invert-paths

# 7. Обновляем origin, если он есть
echo "🌐 Проверяю origin..."
origin_url=$(git remote get-url origin 2>/dev/null || echo "")
if [ -n "$origin_url" ]; then
    echo "🔄 Обновляю репозиторий на GitHub..."
    git push --force --mirror "$origin_url"
else
    echo "⚠️ Origin не найден. Добавь новый удалённый репозиторий вручную."
fi

echo "✅ Готово! Репозиторий очищен и обновлён."
echo "💡 Файлы mp3/mp4 лежат в папке tmp_big (локально, не в git)."
