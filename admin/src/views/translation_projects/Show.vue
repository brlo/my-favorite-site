<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useToast } from "primevue/usetoast"
import Dropdown from 'primevue/dropdown'
import Button from 'primevue/button'
import Textarea from 'primevue/textarea'
import { api } from '@/libs/api.js'

const toast = useToast()
const toastError = (msg) => { toast.add({ severity: 'error', summary: 'Ошибка', detail: msg, life: 5000 }) }
const toastSuccess = (msg) => { toast.add({ severity: 'success', summary: 'Успех', detail: msg, life: 5000 }) }

const props = defineProps({
  translationProjectId: String,
  chapter: Number,
  currentUser: Object
})

// Состояния
const segments = ref([])
const availableSourceLangs = ref([])
const selectedSourceLang = ref('')
const selectedTargetLang = ref('ru')
const newTranslations = ref({}) // { segmentId: 'текст перевода' }
const isLoading = ref(false)

// Фиксированный список языков для перевода
const targetLangs = [
  { name: '🇸🇦 AR - Арабский', code: 'ar' },
  { name: '🇦🇲 HY - Армянский', code: 'hy' },
  { name: '🇨🇳 zh-Hans - Китайский упр.', code: 'zh-Hans' },
  { name: '🇨🇳 zh-Hant - Китайский традиц.', code: 'zh-Hant' },
  { name: '🇩🇪 DE - Немецкий', code: 'de' },
  { name: '🇺🇸 EN - Английский', code: 'en' },
  { name: '🇪🇸 ES - Испанский', code: 'es' },
  { name: '🇫🇷 FR - Французский', code: 'fr' },
  { name: '🇬🇷 EL - Греческий', code: 'el' },
  { name: '🇮🇱 HE - Иврит', code: 'he' },
  { name: '🇮🇳 HI - Хинди', code: 'hi' },
  { name: '🇮🇷 FA - Персидский', code: 'fa' },
  { name: '🇮🇹 IT - Итальянский', code: 'it' },
  { name: '🇯🇵 JA - Японский', code: 'ja' },
  { name: '🇰🇪 SW - Суахили', code: 'sw' },
  { name: '🇰🇷 KO - Корейский', code: 'ko' },
  { name: '🇷🇺 RU - Русский', code: 'ru' },
  { name: '🇷🇸 SR - Сербский', code: 'sr' },
  { name: '🇹🇷 TR - Турецкий', code: 'tr' },
  { name: '🇹🇲 TK - Туркменский', code: 'tk' },
  { name: '🇺🇿 UZ - Узбекский', code: 'uz' },
  { name: '🇻🇳 VI - Вьетнамский', code: 'vi' },
  // ---
  { name: '📜 CU - Церковнославянский', code: 'cu' },
  { name: '🏛️ GRC - Древнегреческий', code: 'grc' },
  { name: '🇻🇦 LA - Латынь', code: 'la' },
  { name: '🇫🇷 FRM - Средневековый французский (Medieval ~1400–1600)', code: 'frm' },
  { name: '🇫🇷 FRO - Старофранцузский (до XIV века)', code: 'fro' },
  { name: '🇪🇬 COP - Коптский', code: 'cop' },
  { name: '🇦🇲 XCL - Древнеармянский (грабар)', code: 'xcl' },
]

// Загрузка данных
const loadData = async () => {
  if (!props.translationProjectId || !props.chapter) return

  isLoading.value = true
  try {
    // Загружаем сегменты для главы
    const segmentsData = api.get(`/translation_projects/${props.translationProjectId}/chapters/${props.chapter}/segments/`)
    segments.value = segmentsData.items

    // Загружаем доступные языки оригинала для этого документа
    const docData = api.get(`/translation_projects/${props.translationProjectId}/`)
    availableSourceLangs.value = docData.source_langs || []

    if (availableSourceLangs.value.length > 0) {
      selectedSourceLang.value = availableSourceLangs.value[0]
    }

  } catch (error) {
    toastError('Ошибка загрузки данных: ' + error.message)
  } finally {
    isLoading.value = false
  }
}

// Голосование за перевод
const voteUp = async (translationId) => {
  try {
    await api.post(`/translations/${translationId}/vote_up/`)
    toastSuccess('Голос учтён')
    loadData() // Перезагружаем данные для обновления счетчиков
  } catch (error) {
    toastError('Ошибка голосования: ' + error.message)
  }
}
const voteDown = async (translationId) => {
  try {
    await api.post(`/translations/${translationId}/vote_down/`)
    toastSuccess('Голос учтён')
    loadData() // Перезагружаем данные для обновления счетчиков
  } catch (error) {
    toastError('Ошибка голосования: ' + error.message)
  }
}

// Добавление нового варианта перевода
const submitTranslation = async (segmentId) => {
  const translationText = newTranslations.value[segmentId]
  if (!translationText?.trim()) {
    toastError('Введите текст перевода')
    return
  }

  try {
    await api.post('/translations/', {
      segment_id: segmentId,
      text: translationText.trim(),
      lang: selectedTargetLang.value,
      source_lang: selectedSourceLang.value
    })

    toastSuccess('Перевод добавлен')
    newTranslations.value[segmentId] = ''
    loadData() // Перезагружаем данные
  } catch (error) {
    toastError('Ошибка добавления перевода: ' + error.message)
  }
}

// Группировка сегментов по параграфам для отображения
const groupedSegments = computed(() => {
  const groups = {}
  segments.value.forEach(segment => {
    const key = `${segment.chapter}-${segment.paragraph}`
    if (!groups[key]) {
      groups[key] = []
    }
    groups[key].push(segment)
  })
  return groups
})

// Отслеживаем изменения параметров
watch(() => [props.translationProjectId, props.chapter], loadData, { immediate: true })
</script>

<template>
  <div class="translation-interface">
    <!-- Заголовок с выбором языков -->
    <div class="translation-header">
      <div class="language-selectors">
        <div class="selector-group">
          <label>Перевод с:</label>
          <Dropdown
            v-model="selectedSourceLang"
            :options="availableSourceLangs.map(lang => ({ label: lang, value: lang }))"
            optionLabel="label"
            optionValue="value"
            placeholder="Выберите язык"
            :disabled="isLoading"
          />
        </div>

        <div class="selector-group">
          <label>Перевод на:</label>
          <Dropdown
            v-model="selectedTargetLang"
            :options="targetLangs"
            optionLabel="name"
            optionValue="code"
            placeholder="Выберите язык"
            :disabled="isLoading"
          />
        </div>
      </div>
    </div>

    <!-- Основной контент - две колонки -->
    <div class="translation-columns">
      <!-- Левая колонка - исходный текст -->
      <div class="source-column">
        <h3>Исходный текст</h3>

        <div v-if="isLoading" class="loading">Загрузка...</div>

        <div v-else class="segments-container">
          <div v-for="(paragraphSegments, key) in groupedSegments" :key="key" class="paragraph-group">
            <div class="paragraph" v-for="segment in paragraphSegments" :key="segment.id">
              <!-- Отображение открывающих тегов -->
              <span v-for="tag in segment.open_tags" :key="`open-${tag}`" v-html="`<${tag}>`" />

              <!-- Текст сегмента -->
              <span class="segment-text">{{ segment.text }}</span>

              <!-- Отображение закрывающих тегов -->
              <span v-for="tag in segment.close_tags" :key="`close-${tag}`" v-html="`</${tag.split('[')[0]}>`" />

              <!-- Адрес сегмента -->
              <div class="segment-address">
                Гл. {{ segment.chapter }}, §{{ segment.paragraph }}
                <span v-if="segment.line">, стр. {{ segment.line }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Правая колонка - переводы -->
      <div class="translations-column">
        <h3>Предложенные переводы</h3>

        <div v-if="isLoading" class="loading">Загрузка...</div>

        <div v-else class="translations-container">
          <div v-for="(paragraphSegments, key) in groupedSegments" :key="key" class="paragraph-group">
            <div v-for="segment in paragraphSegments" :key="segment.id" class="translation-section">
              <!-- Существующие переводы -->
              <div v-for="translation in segment.translations" :key="translation.id" class="translation-item">
                <div class="translation-text">{{ translation.text }}</div>

                <div class="translation-meta">
                  <span class="author">{{ translation.author_name }}</span>
                  <span class="time">{{ new Date(translation.created_at).toLocaleDateString() }}</span>
                  <span class="lang">с {{ translation.source_lang }}</span>
                </div>

                <div class="translation-votes">
                  <span class="score">{{ translation.vote_score }}</span>
                  <Button
                    icon="pi pi-thumbs-up"
                    severity="success"
                    text
                    @click="voteUp(translation.id)"
                    :disabled="!currentUser"
                  />
                  <Button
                    icon="pi pi-thumbs-down"
                    severity="danger"
                    text
                    @click="voteDown(translation.id)"
                    :disabled="!currentUser"
                  />
                </div>
              </div>

              <!-- Форма для нового перевода -->
              <div class="new-translation">
                <Textarea
                  v-model="newTranslations[segment.id]"
                  placeholder="Введите ваш перевод..."
                  rows="2"
                  :disabled="!currentUser"
                />
                <Button
                  label="Добавить перевод"
                  @click="submitTranslation(segment.id)"
                  :disabled="!newTranslations[segment.id]?.trim() || !currentUser"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.translation-interface {
  padding: 20px;
}

.translation-header {
  margin-bottom: 20px;
  padding: 15px;
  background: #f5f5f5;
  border-radius: 8px;
}

.language-selectors {
  display: flex;
  gap: 20px;
  align-items: center;
}

.selector-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.selector-group label {
  font-weight: bold;
  font-size: 0.9em;
}

.translation-columns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  min-height: 500px;
}

.source-column,
.translations-column {
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  overflow-y: auto;
  max-height: 80vh;
}

.source-column h3,
.translations-column h3 {
  margin-top: 0;
  padding-bottom: 10px;
  border-bottom: 2px solid #e0e0e0;
  color: #333;
}

.paragraph-group {
  margin-bottom: 25px;
  padding: 15px;
  border: 1px solid #eee;
  border-radius: 6px;
  background: #fafafa;
}

.paragraph {
  margin-bottom: 15px;
  padding: 10px;
  background: white;
  border-radius: 4px;
  border-left: 3px solid #4CAF50;
}

.segment-text {
  display: block;
  margin: 8px 0;
  font-size: 1.1em;
  line-height: 1.5;
}

.segment-address {
  font-size: 0.8em;
  color: #666;
  margin-top: 5px;
}

.translation-section {
  margin-bottom: 20px;
  padding: 15px;
  background: white;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
}

.translation-item {
  padding: 12px;
  margin-bottom: 12px;
  border: 1px solid #e8e8e8;
  border-radius: 4px;
  background: #f9f9f9;
}

.translation-text {
  font-size: 1em;
  line-height: 1.4;
  margin-bottom: 8px;
}

.translation-meta {
  display: flex;
  gap: 12px;
  font-size: 0.8em;
  color: #666;
  margin-bottom: 8px;
}

.translation-votes {
  display: flex;
  align-items: center;
  gap: 8px;
}

.translation-votes .score {
  font-weight: bold;
  margin-right: 5px;
}

.new-translation {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px dashed #ccc;
}

.new-translation :deep(.p-textarea) {
  width: 100%;
  margin-bottom: 10px;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #666;
}

/* Адаптивность для мобильных устройств */
@media (max-width: 768px) {
  .translation-columns {
    grid-template-columns: 1fr;
  }

  .language-selectors {
    flex-direction: column;
    gap: 10px;
  }
}
</style>
