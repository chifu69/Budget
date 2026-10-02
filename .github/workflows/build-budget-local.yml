#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

UPSTREAM_TAG = "v26.10.0"
UPSTREAM_VERSION = "26.10.0"
ARCHIVE_URL = f"https://github.com/actualbudget/actual/archive/refs/tags/{UPSTREAM_TAG}.zip"
TESSERACT_JS = "6.0.1"
TESSERACT_CORE = "6.1.2"
LANG_DATA = "1.0.0"

SMART_ADD_TSX = 'import React, { useCallback, useMemo, useRef, useState } from \'react\';\n\nimport { Button } from \'@actual-app/components/button\';\nimport { Text } from \'@actual-app/components/text\';\nimport { theme } from \'@actual-app/components/theme\';\nimport { View } from \'@actual-app/components/view\';\n\nimport { useNavigate } from \'#hooks/useNavigate\';\n\nimport { MobileBackButton } from \'./MobileBackButton\';\nimport { MobilePageHeader, Page } from \'../Page\';\nimport {\n  parseReceiptText,\n  parseSmartText,\n  toActualTransactionQuery,\n  type SmartDraft,\n} from \'./smartAddParser\';\n\ntype OcrLog = {\n  status?: string;\n  progress?: number;\n};\n\ntype OcrWorker = {\n  recognize: (image: File | Blob) => Promise<{ data: { text: string } }>;\n  terminate: () => Promise<unknown>;\n};\n\ntype TesseractBrowserApi = {\n  createWorker: (\n    langs?: string | string[],\n    oem?: number,\n    options?: {\n      workerPath?: string;\n      corePath?: string;\n      langPath?: string;\n      workerBlobURL?: boolean;\n      logger?: (message: OcrLog) => void;\n    },\n  ) => Promise<OcrWorker>;\n};\n\ndeclare global {\n  interface Window {\n    Tesseract?: TesseractBrowserApi;\n  }\n}\n\nlet tesseractLoader: Promise<TesseractBrowserApi> | null = null;\n\nfunction loadTesseract(): Promise<TesseractBrowserApi> {\n  if (window.Tesseract) return Promise.resolve(window.Tesseract);\n  if (tesseractLoader) return tesseractLoader;\n\n  tesseractLoader = new Promise((resolve, reject) => {\n    const previous = document.querySelector<HTMLScriptElement>(\n      \'script[data-budget-local-ocr="tesseract"]\',\n    );\n    if (previous) {\n      previous.addEventListener(\'load\', () => {\n        if (window.Tesseract) resolve(window.Tesseract);\n        else reject(new Error(\'No se pudo iniciar el OCR local.\'));\n      });\n      previous.addEventListener(\'error\', () =>\n        reject(new Error(\'No se pudo cargar el OCR local.\')),\n      );\n      return;\n    }\n\n    const script = document.createElement(\'script\');\n    script.src = \'/ocr/tesseract.min.js\';\n    script.async = true;\n    script.dataset.budgetLocalOcr = \'tesseract\';\n    script.onload = () => {\n      if (window.Tesseract) resolve(window.Tesseract);\n      else reject(new Error(\'No se pudo iniciar el OCR local.\'));\n    };\n    script.onerror = () => reject(new Error(\'No se pudo cargar el OCR local.\'));\n    document.head.appendChild(script);\n  });\n\n  return tesseractLoader;\n}\n\nfunction Field({ label, value }: { label: string; value?: string }) {\n  return (\n    <View\n      style={{\n        flex: 1,\n        minWidth: 130,\n        padding: 12,\n        borderRadius: 14,\n        backgroundColor: theme.tableBackground,\n        border: `1px solid ${theme.tableBorder}`,\n      }}\n    >\n      <Text style={{ fontSize: 11, color: theme.pageTextSubdued }}>{label}</Text>\n      <Text style={{ fontSize: 15, fontWeight: 600, marginTop: 3 }}>\n        {value || \'—\'}\n      </Text>\n    </View>\n  );\n}\n\nexport function SmartAdd() {\n  const navigate = useNavigate();\n  const fileInputRef = useRef<HTMLInputElement | null>(null);\n  const [text, setText] = useState(\'\');\n  const [draft, setDraft] = useState<SmartDraft | null>(null);\n  const [ocrProgress, setOcrProgress] = useState<number | null>(null);\n  const [ocrStatus, setOcrStatus] = useState(\'\');\n  const [error, setError] = useState(\'\');\n\n  const reviewEnabled = Boolean(draft?.amount);\n  const confidenceLabel = useMemo(() => {\n    if (draft?.confidence == null) return undefined;\n    return `${Math.round(draft.confidence * 100)}%`;\n  }, [draft?.confidence]);\n\n  const parseTypedText = useCallback(() => {\n    setError(\'\');\n    const parsed = parseSmartText(text);\n    setDraft(parsed);\n    if (!parsed.amount) {\n      setError(\'No encontré una cantidad. Escribe algo como: Walmart 84.72 groceries.\');\n    }\n  }, [text]);\n\n  const openForReview = useCallback(() => {\n    if (!draft) return;\n    const query = toActualTransactionQuery(draft);\n    void navigate(`/smart-review/new${query ? `?${query}` : \'\'}`);\n  }, [draft, navigate]);\n\n  const scanReceipt = useCallback(async (file: File) => {\n    setError(\'\');\n    setDraft(null);\n    setOcrProgress(0);\n    setOcrStatus(\'Preparando OCR local…\');\n\n    let worker: OcrWorker | null = null;\n    try {\n      const api = await loadTesseract();\n      worker = await api.createWorker(\'eng\', 1, {\n        workerPath: \'/ocr/worker.min.js\',\n        corePath: \'/ocr/core\',\n        langPath: \'/ocr/lang\',\n        workerBlobURL: false,\n        logger: message => {\n          if (typeof message.progress === \'number\') {\n            setOcrProgress(Math.max(0, Math.min(1, message.progress)));\n          }\n          if (message.status) setOcrStatus(message.status);\n        },\n      });\n\n      setOcrStatus(\'Leyendo recibo…\');\n      const result = await worker.recognize(file);\n      const parsed = parseReceiptText(result.data.text);\n      setDraft(parsed);\n      setOcrProgress(1);\n      setOcrStatus(\'Listo\');\n      if (!parsed.amount) {\n        setError(\'Leí el recibo, pero no pude identificar el total. Puedes usar entrada manual.\');\n      }\n    } catch (err) {\n      setError(err instanceof Error ? err.message : \'No se pudo leer el recibo.\');\n      setOcrProgress(null);\n      setOcrStatus(\'\');\n    } finally {\n      if (worker) await worker.terminate();\n    }\n  }, []);\n\n  return (\n    <Page\n      header={\n        <MobilePageHeader\n          title="Smart Add"\n          leftContent={<MobileBackButton />}\n        />\n      }\n      padding={0}\n    >\n      <View\n        style={{\n          width: \'100%\',\n          maxWidth: 760,\n          alignSelf: \'center\',\n          padding: 16,\n          paddingBottom: 110,\n          gap: 16,\n        }}\n      >\n        <View\n          style={{\n            padding: 18,\n            borderRadius: 20,\n            backgroundColor: theme.tableBackground,\n            border: `1px solid ${theme.tableBorder}`,\n          }}\n        >\n          <Text style={{ fontSize: 21, fontWeight: 700 }}>Agregar gasto rápido</Text>\n          <Text style={{ marginTop: 6, color: theme.pageTextSubdued, lineHeight: 1.5 }}>\n            Todo se procesa en este dispositivo. La cámara y el OCR no envían el recibo a OpenAI ni a otro servicio de IA.\n          </Text>\n\n          <textarea\n            aria-label="Entrada inteligente"\n            value={text}\n            onChange={event => setText(event.target.value)}\n            placeholder="Ejemplo: Walmart 84.72 category: Groceries account: Checking"\n            rows={4}\n            style={{\n              marginTop: 16,\n              width: \'100%\',\n              resize: \'vertical\',\n              borderRadius: 14,\n              border: `1px solid ${theme.formInputBorder}`,\n              background: theme.formInputBackground,\n              color: theme.formInputText,\n              padding: 14,\n              font: \'inherit\',\n              minHeight: 92,\n            }}\n          />\n\n          <View style={{ flexDirection: \'row\', flexWrap: \'wrap\', gap: 10, marginTop: 12 }}>\n            <Button variant="primary" onPress={parseTypedText}>\n              Interpretar texto\n            </Button>\n            <Button variant="normal" onPress={() => fileInputRef.current?.click()}>\n              📷 Escanear recibo\n            </Button>\n            <Button variant="bare" onPress={() => void navigate(\'/smart-review/new\')}>\n              Entrada manual\n            </Button>\n          </View>\n\n          <input\n            ref={fileInputRef}\n            type="file"\n            accept="image/*"\n            capture="environment"\n            style={{ display: \'none\' }}\n            onChange={event => {\n              const file = event.target.files?.[0];\n              if (file) void scanReceipt(file);\n              event.currentTarget.value = \'\';\n            }}\n          />\n\n          {ocrProgress != null && ocrProgress < 1 && (\n            <View style={{ marginTop: 14 }}>\n              <Text style={{ color: theme.pageTextSubdued }}>\n                {ocrStatus || \'Procesando…\'} {Math.round(ocrProgress * 100)}%\n              </Text>\n              <div\n                style={{\n                  height: 8,\n                  marginTop: 7,\n                  borderRadius: 99,\n                  overflow: \'hidden\',\n                  background: theme.tableBorder,\n                }}\n              >\n                <div\n                  style={{\n                    height: \'100%\',\n                    width: `${Math.round(ocrProgress * 100)}%`,\n                    background: theme.buttonPrimaryBackground,\n                    transition: \'width 160ms ease\',\n                  }}\n                />\n              </div>\n            </View>\n          )}\n\n          {error && (\n            <Text style={{ marginTop: 12, color: theme.errorText }}>{error}</Text>\n          )}\n        </View>\n\n        {draft && (\n          <View\n            style={{\n              padding: 18,\n              borderRadius: 20,\n              backgroundColor: theme.tableBackground,\n              border: `1px solid ${theme.tableBorder}`,\n            }}\n          >\n            <View style={{ flexDirection: \'row\', justifyContent: \'space-between\', gap: 10 }}>\n              <Text style={{ fontSize: 18, fontWeight: 700 }}>Revisión</Text>\n              {confidenceLabel && (\n                <Text style={{ color: theme.pageTextSubdued }}>\n                  Lectura {confidenceLabel}\n                </Text>\n              )}\n            </View>\n\n            <View style={{ flexDirection: \'row\', flexWrap: \'wrap\', gap: 10, marginTop: 14 }}>\n              <Field label="Tipo" value={draft.kind === \'income\' ? \'Ingreso\' : \'Gasto\'} />\n              <Field label="Cantidad" value={draft.amount != null ? `$${draft.amount.toFixed(2)}` : undefined} />\n              <Field label="Comercio" value={draft.payee} />\n              <Field label="Fecha" value={draft.date} />\n              <Field label="Categoría" value={draft.category} />\n              <Field label="Cuenta" value={draft.account} />\n            </View>\n\n            <Text style={{ marginTop: 12, color: theme.pageTextSubdued, lineHeight: 1.45 }}>\n              Antes de guardar, Actual Budget abrirá su formulario normal para que confirmes o corrijas los datos.\n            </Text>\n\n            <View style={{ flexDirection: \'row\', flexWrap: \'wrap\', gap: 10, marginTop: 14 }}>\n              <Button variant="primary" isDisabled={!reviewEnabled} onPress={openForReview}>\n                Revisar y guardar\n              </Button>\n              <Button\n                variant="normal"\n                onPress={() =>\n                  setDraft(current =>\n                    current\n                      ? {\n                          ...current,\n                          kind: current.kind === \'expense\' ? \'income\' : \'expense\',\n                        }\n                      : current,\n                  )\n                }\n              >\n                Cambiar a {draft.kind === \'expense\' ? \'ingreso\' : \'gasto\'}\n              </Button>\n            </View>\n          </View>\n        )}\n\n        <View\n          style={{\n            padding: 16,\n            borderRadius: 18,\n            backgroundColor: theme.noticeBackground,\n          }}\n        >\n          <Text style={{ fontWeight: 700 }}>Privacidad local</Text>\n          <Text style={{ marginTop: 5, color: theme.pageTextSubdued, lineHeight: 1.45 }}>\n            OCR: Tesseract.js ejecutándose en el navegador. Sin voz, sin OpenAI API, sin Firebase y sin Supabase para esta función.\n          </Text>\n        </View>\n      </View>\n    </Page>\n  );\n}\n'
SMART_ADD_PARSER_TS = 'export type SmartDraft = {\n  kind: \'expense\' | \'income\';\n  amount?: number;\n  payee?: string;\n  category?: string;\n  account?: string;\n  date?: string;\n  notes?: string;\n  sourceText?: string;\n  confidence?: number;\n};\n\nfunction cleanSpaces(value: string): string {\n  return value.replace(/\\s+/g, \' \').trim();\n}\n\nfunction cleanLabel(value?: string): string | undefined {\n  if (!value) return undefined;\n  const cleaned = cleanSpaces(value.replace(/^[\\s,:;\\-–—]+|[\\s,:;\\-–—]+$/g, \'\'));\n  return cleaned || undefined;\n}\n\nfunction normalizeAmount(value: string): number | undefined {\n  const normalized = value\n    .replace(/[$,]/g, \'\')\n    .replace(/[Oo](?=\\d)/g, \'0\')\n    .replace(/(?<=\\d)[Oo]/g, \'0\');\n  const parsed = Number.parseFloat(normalized);\n  if (!Number.isFinite(parsed) || parsed <= 0 || parsed > 100000000) {\n    return undefined;\n  }\n  return Math.round(parsed * 100) / 100;\n}\n\nfunction findAmount(text: string): number | undefined {\n  const matches = [...text.matchAll(/(?:\\$\\s*)?(\\d{1,3}(?:,\\d{3})*|\\d+)[.](\\d{2})\\b/g)];\n  if (matches.length === 0) return undefined;\n  return normalizeAmount(matches[0][0]);\n}\n\nfunction isoFromParts(month: number, day: number, year: number): string | undefined {\n  const fullYear = year < 100 ? (year >= 70 ? 1900 + year : 2000 + year) : year;\n  const date = new Date(fullYear, month - 1, day);\n  if (\n    date.getFullYear() !== fullYear ||\n    date.getMonth() !== month - 1 ||\n    date.getDate() !== day\n  ) {\n    return undefined;\n  }\n  return `${String(fullYear).padStart(4, \'0\')}-${String(month).padStart(2, \'0\')}-${String(day).padStart(2, \'0\')}`;\n}\n\nexport function extractDate(text: string, now = new Date()): string | undefined {\n  const lower = text.toLowerCase();\n  if (/\\b(today|hoy)\\b/.test(lower)) {\n    return isoFromParts(now.getMonth() + 1, now.getDate(), now.getFullYear());\n  }\n  if (/\\b(yesterday|ayer)\\b/.test(lower)) {\n    const d = new Date(now);\n    d.setDate(d.getDate() - 1);\n    return isoFromParts(d.getMonth() + 1, d.getDate(), d.getFullYear());\n  }\n\n  const iso = text.match(/\\b(20\\d{2})[-/.](\\d{1,2})[-/.](\\d{1,2})\\b/);\n  if (iso) {\n    return isoFromParts(Number(iso[2]), Number(iso[3]), Number(iso[1]));\n  }\n\n  const us = text.match(/\\b(\\d{1,2})[/-](\\d{1,2})[/-](\\d{2,4})\\b/);\n  if (us) {\n    return isoFromParts(Number(us[1]), Number(us[2]), Number(us[3]));\n  }\n\n  const monthNames: Record<string, number> = {\n    jan: 1,\n    january: 1,\n    ene: 1,\n    enero: 1,\n    feb: 2,\n    february: 2,\n    febrero: 2,\n    mar: 3,\n    march: 3,\n    marzo: 3,\n    apr: 4,\n    april: 4,\n    abr: 4,\n    abril: 4,\n    may: 5,\n    mayo: 5,\n    jun: 6,\n    june: 6,\n    junio: 6,\n    jul: 7,\n    july: 7,\n    julio: 7,\n    aug: 8,\n    august: 8,\n    ago: 8,\n    agosto: 8,\n    sep: 9,\n    sept: 9,\n    september: 9,\n    septiembre: 9,\n    oct: 10,\n    october: 10,\n    octubre: 10,\n    nov: 11,\n    november: 11,\n    noviembre: 11,\n    dec: 12,\n    december: 12,\n    dic: 12,\n    diciembre: 12,\n  };\n  const wordDate = lower.match(\n    /\\b(jan(?:uary)?|ene(?:ro)?|feb(?:ruary|rero)?|mar(?:ch|zo)?|apr(?:il)?|abr(?:il)?|may|mayo|jun(?:e|io)?|jul(?:y|io)?|aug(?:ust)?|ago(?:sto)?|sep(?:t(?:ember)?)?|septiembre|oct(?:ober|ubre)?|nov(?:ember|iembre)?|dec(?:ember)?|dic(?:iembre)?)\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(\\d{2,4}))?\\b/,\n  );\n  if (wordDate) {\n    const month = monthNames[wordDate[1]];\n    const year = wordDate[3] ? Number(wordDate[3]) : now.getFullYear();\n    return isoFromParts(month, Number(wordDate[2]), year);\n  }\n  return undefined;\n}\n\nfunction extractTaggedValue(text: string, labels: string[]): string | undefined {\n  const escaped = labels.map(label => label.replace(/[.*+?^${}()|[\\]\\\\]/g, \'\\\\$&\'));\n  const nextTag = \'(?:category|categoria|categoría|account|cuenta|payee|comercio|merchant)\';\n  const regex = new RegExp(\n    `(?:^|\\\\s)(?:${escaped.join(\'|\')})\\\\s*[:=]\\\\s*(?:"([^"]+)"|\'([^\']+)\'|(.+?))(?=\\\\s+${nextTag}\\\\s*[:=]|[,;\\\\n]|$)`,\n    \'i\',\n  );\n  const match = text.match(regex);\n  return cleanLabel(match?.[1] || match?.[2] || match?.[3]);\n}\n\nfunction stripTaggedValues(text: string): string {\n  return text.replace(\n    /(?:^|\\s)(?:category|categoria|categoría|account|cuenta|payee|comercio|merchant)\\s*[:=]\\s*(?:"[^"]+"|\'[^\']+\'|.+?)(?=\\s+(?:category|categoria|categoría|account|cuenta|payee|comercio|merchant)\\s*[:=]|[,;\\n]|$)/gi,\n    \' \',\n  );\n}\n\nexport function parseSmartText(text: string, now = new Date()): SmartDraft {\n  const sourceText = cleanSpaces(text);\n  const lower = sourceText.toLowerCase();\n  const kind: SmartDraft[\'kind\'] = /\\b(income|ingreso|salary|salario|paycheck|deposit|depósito|deposito|refund|reembolso)\\b/.test(\n    lower,\n  )\n    ? \'income\'\n    : \'expense\';\n\n  const explicitPayee = extractTaggedValue(sourceText, [\'payee\', \'merchant\', \'comercio\']);\n  const category =\n    extractTaggedValue(sourceText, [\'category\', \'categoria\', \'categoría\']) ||\n    cleanLabel(sourceText.match(/(?:^|\\s)#([\\p{L}\\p{N}_ -]{2,40})/u)?.[1]);\n  const account =\n    extractTaggedValue(sourceText, [\'account\', \'cuenta\']) ||\n    cleanLabel(sourceText.match(/(?:^|\\s)@([\\p{L}\\p{N}_ -]{2,40})/u)?.[1]);\n\n  const amountMatch = sourceText.match(\n    /(?:\\$\\s*)?(\\d{1,3}(?:,\\d{3})*|\\d+)[.](\\d{2})\\b|(?:\\$\\s*)(\\d+(?:\\.\\d{1,2})?)/,\n  );\n  const amount = amountMatch ? normalizeAmount(amountMatch[0]) : undefined;\n  const date = extractDate(sourceText, now);\n\n  let payee = explicitPayee;\n  if (!payee && amountMatch?.index != null) {\n    let beforeAmount = stripTaggedValues(sourceText.slice(0, amountMatch.index));\n    beforeAmount = beforeAmount\n      .replace(/\\b(expense|gasto|income|ingreso|paid|pagu[eé]|spent|gast[eé]|at|en|from|de)\\b/gi, \' \')\n      .replace(/[#@][\\p{L}\\p{N}_ -]+/gu, \' \');\n    payee = cleanLabel(beforeAmount);\n  }\n\n  return {\n    kind,\n    amount,\n    payee,\n    category,\n    account,\n    date,\n    notes: sourceText || undefined,\n    sourceText,\n    confidence: amount ? 0.8 : 0.45,\n  };\n}\n\nfunction amountsInLine(line: string): number[] {\n  return [...line.matchAll(/(?:\\$\\s*)?(\\d{1,3}(?:,\\d{3})*|\\d+)[.](\\d{2})\\b/g)]\n    .map(match => normalizeAmount(match[0]))\n    .filter((value): value is number => value != null);\n}\n\nfunction likelyMerchant(lines: string[]): string | undefined {\n  const ignored = /\\b(receipt|thank|thanks|welcome|cashier|register|store\\s*#|www\\.|http|tel|phone|date|time|subtotal|total|tax)\\b/i;\n  for (const line of lines.slice(0, 8)) {\n    const cleaned = cleanSpaces(line.replace(/[|_*~]+/g, \' \'));\n    const letters = (cleaned.match(/[A-Za-zÀ-ÿ]/g) || []).length;\n    if (cleaned.length >= 3 && cleaned.length <= 70 && letters >= 3 && !ignored.test(cleaned)) {\n      return cleaned;\n    }\n  }\n  return undefined;\n}\n\nexport function parseReceiptText(text: string, now = new Date()): SmartDraft {\n  const rawLines = text\n    .split(/\\r?\\n/)\n    .map(line => cleanSpaces(line))\n    .filter(Boolean);\n\n  const prioritized: Array<{ priority: number; amount: number }> = [];\n  for (const line of rawLines) {\n    const lower = line.toLowerCase();\n    if (/\\b(sub\\s*total|subtotal|tax|change|cash|tender)\\b/.test(lower)) continue;\n    const values = amountsInLine(line);\n    if (values.length === 0) continue;\n\n    let priority = 0;\n    if (/\\b(grand\\s*total|amount\\s*due|balance\\s*due|total\\s*due)\\b/.test(lower)) priority = 100;\n    else if (/\\btotal\\b/.test(lower)) priority = 90;\n    else if (/\\b(amount|due|paid)\\b/.test(lower)) priority = 65;\n\n    for (const amount of values) prioritized.push({ priority, amount });\n  }\n\n  let amount: number | undefined;\n  if (prioritized.length > 0) {\n    prioritized.sort((a, b) => b.priority - a.priority || b.amount - a.amount);\n    if (prioritized[0].priority > 0) {\n      amount = prioritized[0].amount;\n    } else {\n      const bottomHalf = rawLines.slice(Math.floor(rawLines.length / 2));\n      const fallback = bottomHalf.flatMap(amountsInLine);\n      if (fallback.length > 0) amount = Math.max(...fallback);\n    }\n  }\n\n  const date = rawLines.map(line => extractDate(line, now)).find(Boolean);\n  const payee = likelyMerchant(rawLines);\n  const confidence = amount ? (payee ? 0.88 : 0.78) : 0.4;\n\n  return {\n    kind: \'expense\',\n    amount,\n    payee,\n    date,\n    notes: payee\n      ? `Escaneado localmente desde recibo — comercio: ${payee}`\n      : \'Escaneado localmente desde recibo\',\n    sourceText: text,\n    confidence,\n  };\n}\n\nexport function toActualTransactionQuery(draft: SmartDraft): string {\n  const params = new URLSearchParams();\n  if (draft.amount != null) {\n    // Actual\'s mobile new-transaction route negates this query value.\n    // Positive query => expense. Negative query => income.\n    const queryAmount = draft.kind === \'income\' ? -Math.abs(draft.amount) : Math.abs(draft.amount);\n    params.set(\'amount\', queryAmount.toFixed(2));\n  }\n  if (draft.payee) params.set(\'payee\', draft.payee);\n  if (draft.category) params.set(\'category\', draft.category);\n  if (draft.account) params.set(\'account\', draft.account);\n  if (draft.date) params.set(\'date\', draft.date);\n  if (draft.notes) params.set(\'notes\', draft.notes);\n  return params.toString();\n}\n'

OCR_FILES = {
    "tesseract.min.js": f"https://cdn.jsdelivr.net/npm/tesseract.js@{TESSERACT_JS}/dist/tesseract.min.js",
    "worker.min.js": f"https://cdn.jsdelivr.net/npm/tesseract.js@{TESSERACT_JS}/dist/worker.min.js",
    "core/tesseract-core.wasm.js": f"https://cdn.jsdelivr.net/npm/tesseract.js-core@{TESSERACT_CORE}/tesseract-core.wasm.js",
    "core/tesseract-core-simd.wasm.js": f"https://cdn.jsdelivr.net/npm/tesseract.js-core@{TESSERACT_CORE}/tesseract-core-simd.wasm.js",
    "core/tesseract-core-lstm.wasm.js": f"https://cdn.jsdelivr.net/npm/tesseract.js-core@{TESSERACT_CORE}/tesseract-core-lstm.wasm.js",
    "core/tesseract-core-simd-lstm.wasm.js": f"https://cdn.jsdelivr.net/npm/tesseract.js-core@{TESSERACT_CORE}/tesseract-core-simd-lstm.wasm.js",
    "lang/eng.traineddata.gz": f"https://cdn.jsdelivr.net/npm/@tesseract.js-data/eng@{LANG_DATA}/4.0.0_best_int/eng.traineddata.gz",
}


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if new in text:
        return
    if old not in text:
        fail(f"No encontré el bloque esperado para {label} en {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def remove_once(path: Path, old: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        return
    path.write_text(text.replace(old, "", 1), encoding="utf-8")


def download(url: str, destination: Path, label: str) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    print(f"Descargando {label}...")
    request = urllib.request.Request(url, headers={"User-Agent": "Budget-Local-iPhone/0.1"})
    with urllib.request.urlopen(request, timeout=180) as response, destination.open("wb") as output:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            output.write(chunk)


def fetch_ocr(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists() and destination.stat().st_size > 1024:
        return
    download(url, destination, destination.name)
    if destination.stat().st_size < 1024:
        destination.unlink(missing_ok=True)
        fail(f"Descarga OCR inválida: {url}")


def apply_mod(root: Path) -> None:
    package_path = root / "packages/desktop-client/package.json"
    if not package_path.exists():
        fail("La carpeta destino no parece ser Actual Budget.")

    package = json.loads(package_path.read_text(encoding="utf-8"))
    if package.get("version") != UPSTREAM_VERSION:
        fail(
            f"Este mod está fijado a Actual Budget {UPSTREAM_VERSION}; "
            f"encontré {package.get('version')!r}."
        )

    mobile_dir = root / "packages/desktop-client/src/components/mobile"
    mobile_dir.mkdir(parents=True, exist_ok=True)
    (mobile_dir / "SmartAdd.tsx").write_text(SMART_ADD_TSX, encoding="utf-8")
    (mobile_dir / "smartAddParser.ts").write_text(SMART_ADD_PARSER_TS, encoding="utf-8")

    finances = root / "packages/desktop-client/src/components/FinancesApp.tsx"
    replace_once(
        finances,
        "import { MobileNavTabs } from './mobile/MobileNavTabs';\n",
        "import { MobileNavTabs } from './mobile/MobileNavTabs';\nimport { SmartAdd } from './mobile/SmartAdd';\n",
        "import SmartAdd",
    )
    replace_once(
        finances,
        '                    <Route path="/reports/*" element={<Reports />} />\n',
        '                    <Route path="/reports/*" element={<Reports />} />\n\n'
        '                    <Route path="/smart-add" element={<SmartAdd />} />\n',
        "ruta Smart Add",
    )
    replace_once(
        finances,
        '                    <Route path="/smart-add" element={<SmartAdd />} />\n',
        '                    <Route path="/smart-add" element={<SmartAdd />} />\n\n'
        '                    <Route\n'
        '                      path="/smart-review/:transactionId"\n'
        '                      element={\n'
        '                        <ErrorBoundary\n'
        '                          FallbackComponent={FeatureErrorFallback}\n'
        '                          resetKeys={[location.pathname]}\n'
        '                        >\n'
        '                          <TransactionEdit />\n'
        '                        </ErrorBoundary>\n'
        '                      }\n'
        '                    />\n',
        "ruta de revisión Smart Add",
    )
    replace_once(
        finances,
        '                  <Route path="/budget" element={<MobileNavTabs />} />\n',
        '                  <Route path="/budget" element={<MobileNavTabs />} />\n'
        '                  <Route path="/smart-add" element={<MobileNavTabs />} />\n',
        "barra móvil Smart Add",
    )

    nav = root / "packages/desktop-client/src/components/mobile/MobileNavTabs.tsx"
    replace_once(
        nav,
        "  SvgCog,\n  SvgCreditCard,\n  SvgPiggyBank,\n",
        "  SvgCog,\n  SvgPiggyBank,\n",
        "quitar icono Bank Sync móvil",
    )
    remove_once(nav, "import { useIsTestEnv } from '#hooks/useIsTestEnv';\n", "hook test móvil")
    remove_once(nav, "import { useSyncServerStatus } from '#hooks/useSyncServerStatus';\n", "hook sync móvil")
    remove_once(
        nav,
        "  const syncServerStatus = useSyncServerStatus();\n"
        "  const isTestEnv = useIsTestEnv();\n"
        "  const isUsingServer = syncServerStatus !== 'no-server' || isTestEnv;\n",
        "estado Bank Sync móvil",
    )
    replace_once(
        nav,
        "      name: t('Transaction'),\n      path: '/transactions/new',\n",
        "      name: t('Smart Add'),\n      path: '/smart-add',\n",
        "tab Smart Add",
    )
    remove_once(
        nav,
        "    ...(isUsingServer\n"
        "      ? [\n"
        "          {\n"
        "            name: t('Bank Sync'),\n"
        "            path: '/bank-sync',\n"
        "            style: navTabStyle,\n"
        "            Icon: SvgCreditCard,\n"
        "          },\n"
        "        ]\n"
        "      : []),\n",
        "Bank Sync móvil",
    )

    primary = root / "packages/desktop-client/src/components/sidebar/PrimaryButtons.tsx"
    replace_once(
        primary,
        "  SvgCheveronRight,\n  SvgCog,\n  SvgCreditCard,\n  SvgReports,\n",
        "  SvgCheveronRight,\n  SvgCog,\n  SvgAdd,\n  SvgReports,\n",
        "iconos sidebar",
    )
    remove_once(primary, "import { useIsTestEnv } from '#hooks/useIsTestEnv';\n", "hook test sidebar")
    remove_once(primary, "import { useSyncServerStatus } from '#hooks/useSyncServerStatus';\n", "hook sync sidebar")
    remove_once(
        primary,
        "  const syncServerStatus = useSyncServerStatus();\n"
        "  const isTestEnv = useIsTestEnv();\n"
        "  const isUsingServer = syncServerStatus !== 'no-server' || isTestEnv;\n\n",
        "estado Bank Sync sidebar",
    )
    replace_once(
        primary,
        "      <Item title={t('Budget')} Icon={SvgWallet} to=\"/budget\" />\n"
        "      <Item title={t('Reports')} Icon={SvgReports} to=\"/reports\" />\n",
        "      <Item title={t('Budget')} Icon={SvgWallet} to=\"/budget\" />\n"
        "      <Item title={t('Smart Add')} Icon={SvgAdd} to=\"/smart-add\" />\n"
        "      <Item title={t('Reports')} Icon={SvgReports} to=\"/reports\" />\n",
        "Smart Add sidebar",
    )
    remove_once(
        primary,
        "          {isUsingServer && (\n"
        "            <SecondaryItem\n"
        "              title={t('Bank Sync')}\n"
        "              Icon={SvgCreditCard}\n"
        "              to=\"/bank-sync\"\n"
        "              indent={15}\n"
        "            />\n"
        "          )}\n",
        "Bank Sync sidebar",
    )

    vite = root / "packages/desktop-client/vite.config.mts"
    replace_once(
        vite,
        "                '**/*.{js,css,html,txt,wasm,sql,sqlite,ico,png,woff2,webmanifest}',\n",
        "                '**/*.{js,css,html,txt,wasm,sql,sqlite,ico,png,woff2,webmanifest,gz}',\n",
        "precache OCR gzip",
    )

    manifest_path = root / "packages/desktop-client/public/site.webmanifest"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["name"] = "Budget Local"
    manifest["short_name"] = "Budget Local"
    manifest["description"] = "Finanzas local-first con captura inteligente y OCR local"
    if manifest.get("shortcuts"):
        manifest["shortcuts"][0]["name"] = "Smart Add"
        manifest["shortcuts"][0]["short_name"] = "Smart Add"
        manifest["shortcuts"][0]["description"] = "Agregar gasto por texto o recibo"
        manifest["shortcuts"][0]["url"] = "/smart-add"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    index = root / "packages/desktop-client/index.html"
    replace_once(index, "    <title>Actual</title>\n", "    <title>Budget Local</title>\n", "título PWA")

    marker = root / "BUDGET-LOCAL-MOD.md"
    marker.write_text(
        "# Budget Local mod\n\n"
        f"Base: Actual Budget v{UPSTREAM_VERSION}.\n\n"
        "Cambios iniciales:\n"
        "- Smart Add por texto.\n"
        "- Cámara/galería con OCR Tesseract.js local.\n"
        "- Revisión obligatoria mediante el editor normal de Actual antes de guardar.\n"
        "- Bank Sync oculto de la navegación; el código upstream se conserva.\n"
        "- Branding PWA inicial Budget Local.\n"
        "- Sin OpenAI, Firebase o Supabase para Smart Add.\n\n"
        "El motor financiero de Actual Budget no fue reemplazado.\n",
        encoding="utf-8",
    )


def prepare_ocr(root: Path) -> None:
    public_ocr = root / "packages/desktop-client/public/ocr"
    for relative, url in OCR_FILES.items():
        fetch_ocr(url, public_ocr / relative)
    (public_ocr / "NOTICE.txt").write_text(
        "Budget Local - OCR local vendorizado\n\n"
        f"Tesseract.js {TESSERACT_JS} (Apache-2.0)\n"
        f"tesseract.js-core {TESSERACT_CORE} (Apache-2.0)\n"
        f"English traineddata package {LANG_DATA}\n\n"
        "Los archivos se sirven desde /ocr y el recibo se procesa en el navegador.\n"
        "No se requiere CDN ni API de OCR en tiempo de ejecución.\n",
        encoding="utf-8",
    )


def create_project(destination: Path, archive: Path | None, force: bool) -> None:
    if destination.exists():
        if not force:
            fail(f"La carpeta ya existe: {destination}. Usa --force para reemplazarla.")
        shutil.rmtree(destination)

    with tempfile.TemporaryDirectory(prefix="budget-local-") as temp_dir:
        temp = Path(temp_dir)
        local_archive = temp / "actual.zip"
        if archive:
            shutil.copy2(archive, local_archive)
            print(f"Usando archivo local: {archive}")
        else:
            download(ARCHIVE_URL, local_archive, f"Actual Budget {UPSTREAM_TAG}")
        print("Extrayendo base oficial...")
        with zipfile.ZipFile(local_archive) as zf:
            zf.extractall(temp / "extract")
        extracted = next((temp / "extract").iterdir())
        shutil.move(str(extracted), str(destination))

    print("Aplicando Budget Local...")
    apply_mod(destination)
    print("Preparando OCR local...")
    prepare_ocr(destination)
    print(f"OK: proyecto listo en {destination}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Crea Budget Local sobre Actual Budget desde un solo archivo")
    parser.add_argument("--dest", default="actual-budget-local", help="Carpeta destino")
    parser.add_argument("--force", action="store_true", help="Reemplaza la carpeta destino")
    parser.add_argument("--archive", help="ZIP local de Actual Budget v26.10.0 para pruebas sin red")
    args = parser.parse_args()
    archive = Path(args.archive).resolve() if args.archive else None
    if archive and not archive.exists():
        fail(f"No existe el archivo: {archive}")
    create_project(Path(args.dest).resolve(), archive, args.force)


if __name__ == "__main__":
    main()
