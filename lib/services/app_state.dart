import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/task.dart';
import '../models/meta.dart';
import '../models/recurrence.dart';
import '../models/day_data.dart';
import '../models/notification_prefs.dart';
import 'auth_service.dart';
import 'habit_suggestions.dart';
import 'notification_service.dart';

/// Estado central do app — equivalente ao objeto `state` + funções de
/// manipulação (load/save/toggleTask/checkIn/etc.) do index.html original.
/// Usa ChangeNotifier + SharedPreferences (equivalente ao localStorage).
class AppState extends ChangeNotifier {
  static const _kStateKey = 'rotina_state';
  static const _kOnboardingKey = 'rotina_onboarding_done';
  static const _kWelcomeAssistantKey = 'rotina_welcome_assistant_done';
  static const _kDayPrefix = 'day_';
  // Token guardado no Keystore/Keychain — não no SharedPreferences
  static const _kTokenKey = 'rotina_auth_token';
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<Task> tasks = [];
  List<Meta> metas = [];
  SleepData sleep = SleepData();
  bool isDark = true;
  int focusSeconds = 0;
  String? authToken;
  String userEmail = '';
  String userName = '';
  String? avatarPath;
  NotificationPrefs notifPrefs = NotificationPrefs();

  bool onboardingDone = false;
  bool welcomeAssistantDone = false;
  bool _loaded = false;
  bool get loaded => _loaded;

  // Dados de fundador (vêm do servidor no login/cadastro)
  bool isFounder = false;
  int? founderPosition;
  bool emailVerified = false;
  static const _kFounderKey = 'rotina_is_founder';
  static const _kFounderPosKey = 'rotina_founder_position';
  static const _kEmailVerifiedKey = 'rotina_email_verified';

  late SharedPreferences _prefs;

  /// Carrega o estado salvo (equivalente a `load()`).
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getString(_kStateKey);
    if (saved != null) {
      try {
        final map = jsonDecode(saved) as Map<String, dynamic>;
        tasks = (map['tasks'] as List? ?? [])
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        metas = (map['metas'] as List? ?? [])
            .map((e) => Meta.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        sleep = SleepData.fromJson(
          map['sleep'] != null ? Map<String, dynamic>.from(map['sleep']) : null,
        );
        isDark = (map['theme'] as String? ?? 'dark') == 'dark';
        focusSeconds = (map['focusSeconds'] as num?)?.toInt() ?? 0;
        userName = map['userName'] as String? ?? '';
        avatarPath = map['avatarPath'] as String?;
        notifPrefs = NotificationPrefs.fromJson(
          map['notifPrefs'] != null ? Map<String, dynamic>.from(map['notifPrefs']) : null,
        );
      } catch (_) {
        // dados corrompidos: mantém defaults
      }
    }
    onboardingDone = _prefs.getBool(_kOnboardingKey) ?? false;
    welcomeAssistantDone = _prefs.getBool(_kWelcomeAssistantKey) ?? false;
    authToken = await _secureStorage.read(key: _kTokenKey);
    isFounder = _prefs.getBool(_kFounderKey) ?? false;
    founderPosition = _prefs.getInt(_kFounderPosKey);
    emailVerified = _prefs.getBool(_kEmailVerifiedKey) ?? false;

    // Bug 2 fix: reseta o done de todas as tarefas se o último reset
    // foi em outro dia — garante que tarefas recorrentes comecem desmarcadas.
    _resetDoneIfNewDay();

    _loaded = true;
    notifyListeners();
    unawaited(_rescheduleNotifications());
  }

  static const _kLastResetKey = 'rotina_last_reset_date';

  void _resetDoneIfNewDay() {
    final today = _fmtDate(DateTime.now());
    final lastReset = _prefs.getString(_kLastResetKey) ?? '';
    if (lastReset != today) {
      for (final t in tasks) {
        t.done = false;
      }
      _prefs.setString(_kLastResetKey, today);
    }
  }

  /// Persiste o estado (equivalente a `save()`).
  Future<void> save() async {
    final map = {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'metas': metas.map((m) => m.toJson()).toList(),
      'sleep': sleep.toJson(),
      'theme': isDark ? 'dark' : 'light',
      'focusSeconds': focusSeconds,
      'userName': userName,
      'avatarPath': avatarPath,
      'notifPrefs': notifPrefs.toJson(),
    };
    await _prefs.setString(_kStateKey, jsonEncode(map));
    notifyListeners();
    unawaited(_rescheduleNotifications());
    // Bug 5 fix: sincroniza com servidor em background sempre que salvar
    if (authToken != null) {
      unawaited(syncToServer());
    }
  }

  /// Reagenda os lembretes locais com base no estado atual. É chamado
  /// automaticamente após qualquer save() — silencioso em caso de falha
  /// (ex: permissão negada) para não quebrar o salvamento dos dados.
  Future<void> _rescheduleNotifications() async {
    try {
      await NotificationService.instance.rescheduleAll(
        tasks: tasks,
        taskReminderBefore: notifPrefs.taskReminderBefore,
        taskReminderMinutesBefore: notifPrefs.taskReminderMinutesBefore,
        taskReminderAtTime: notifPrefs.taskReminderAtTime,
        endOfDayReminder: notifPrefs.endOfDayReminder,
        endOfDayHour: notifPrefs.endOfDayHour,
        endOfDayMinute: notifPrefs.endOfDayMinute,
        sleepReminder: notifPrefs.sleepReminder,
        sleepReminderMinutesBefore: notifPrefs.sleepReminderMinutesBefore,
        sleepTime: sleep.start,
        goodMorning: notifPrefs.goodMorning,
        wakeTime: sleep.end,
        weeklyMetaSummary: notifPrefs.weeklyMetaSummary,
      );
    } catch (_) {
      // notificações são um extra — não derruba o app se falhar
    }
  }

  /// Atualiza as preferências de notificação e reagenda tudo.
  Future<void> updateNotificationPrefs(NotificationPrefs prefs) async {
    notifPrefs = prefs;
    await save();
  }

  // ── ASSISTENTE DE BOAS-VINDAS ──
  /// Marca o assistente como concluído (aceito ou recusado), para não
  /// exibir o modal novamente em sessões futuras.
  Future<void> dismissWelcomeAssistant() async {
    welcomeAssistantDone = true;
    await _prefs.setBool(_kWelcomeAssistantKey, true);
    notifyListeners();
  }

  int _idSeed = DateTime.now().millisecondsSinceEpoch;
  int _nextId() => _idSeed++;
  /// Bug 7 fix: expõe o gerador central de IDs para widgets externos
  /// (ex: add_edit_sheet), evitando colisões com millisecondsSinceEpoch.
  int nextId() => _idSeed++;

  /// Cria uma meta a partir de uma [SuggestedMeta] e suas tarefas vinculadas.
  void _addSuggestedMeta(SuggestedMeta sm) {
    final metaId = _nextId();
    metas.add(Meta(
      id: metaId,
      name: sm.name,
      type: sm.type,
      target: sm.target,
      unit: sm.unit,
      color: sm.color,
    ));
    for (final st in sm.tasks) {
      _addSuggestedTask(st, linkedMeta: metaId);
    }
  }

  /// Cria uma tarefa a partir de uma [SuggestedTask], opcionalmente
  /// vinculada a uma meta.
  void _addSuggestedTask(SuggestedTask st, {int? linkedMeta}) {
    tasks.add(Task(
      id: _nextId(),
      name: st.name,
      time: st.time,
      weight: st.weight,
      recurrence: Recurrence(
        mode: RecMode.repeat,
        freq: st.recurDays.length,
        period: RecPeriod.semana,
        days: st.recurDays,
      ),
      linkedMeta: linkedMeta,
    ));
  }

  /// Aplica as metas (e tarefas vinculadas) das categorias escolhidas pelo
  /// usuário no assistente de boas-vindas. Também grava o horário de sono
  /// padrão informado no questionário, via [setDefaultSleep].
  Future<void> applySuggestedCategories(
    List<HabitCategory> categories,
    RoutineProfile profile,
  ) async {
    sleep = SleepData(start: profile.sleepTime, end: profile.wakeTime);
    for (final cat in categories) {
      for (final sm in cat.metas) {
        _addSuggestedMeta(sm);
      }
    }
    await save();
  }

  /// Aplica os hábitos extras escolhidos na etapa "quer ampliar mais seu
  /// dia?". Cada [ExtraHabit] gera sempre a tarefa solta e, se ele tiver
  /// uma [SuggestedMeta] associada, também cria a metinha vinculada.
  Future<void> applyExtraHabits(List<ExtraHabit> extras) async {
    for (final extra in extras) {
      if (extra.meta != null) {
        final metaId = _nextId();
        final sm = extra.meta!;
        metas.add(Meta(
          id: metaId,
          name: sm.name,
          type: sm.type,
          target: sm.target,
          unit: sm.unit,
          color: sm.color,
        ));
        _addSuggestedTask(extra.task, linkedMeta: metaId);
      } else {
        _addSuggestedTask(extra.task);
      }
    }
    await save();
  }

  // ── AUTH ──
  /// Salva token + dados do usuário após login ou cadastro bem-sucedido.
  /// [isNewUser] = true no cadastro (não faz pull pois não há dados no servidor).
  Future<void> saveAuthSession(
    String token,
    Map<String, dynamic> user, {
    bool isNewUser = false,
  }) async {
    authToken = token;
    userEmail = (user['email'] as String?) ?? userEmail;
    userName = (user['nome'] as String?) ?? userName;
    isFounder = (user['isFounder'] as bool?) ?? false;
    founderPosition = (user['founderPosition'] as int?);
    emailVerified = (user['emailVerified'] as bool?) ?? false;
    // Marca se é usuário novo para o HomeShell decidir se mostra o welcome flow
    _justRegistered = isNewUser;
    await _secureStorage.write(key: _kTokenKey, value: token);
    await _prefs.setBool(_kFounderKey, isFounder);
    await _prefs.setBool(_kEmailVerifiedKey, emailVerified);
    if (founderPosition != null) {
      await _prefs.setInt(_kFounderPosKey, founderPosition!);
    }
    if (!isNewUser) {
      // Login de usuário existente: tenta restaurar dados do servidor
      await syncFromServer();
    } else {
      await save();
    }
    notifyListeners();
  }

  /// Marca o email como verificado localmente (após código confirmado).
  Future<void> markEmailVerified() async {
    emailVerified = true;
    await _prefs.setBool(_kEmailVerifiedKey, true);
    notifyListeners();
  }

  /// True apenas durante a sessão em que o usuário acabou de se cadastrar.
  /// Resetado após o HomeShell exibir o welcome flow uma vez.
  bool _justRegistered = false;
  bool get justRegistered => _justRegistered;

  /// Chamado pelo HomeShell após exibir o welcome flow para não repetir.
  void clearJustRegistered() {
    _justRegistered = false;
  }

  // ── SYNC (Bug 5 fix) ──
  /// Envia o estado local para o servidor.
  Future<bool> syncToServer() async {
    if (authToken == null) return true;
    final result = await AuthService.pushData(
      token: authToken!,
      data: exportJson(),
    );
    return result.success;
  }

  /// Busca dados do servidor e substitui o estado local.
  /// Usado no primeiro login para restaurar dados de outro dispositivo.
  /// Bug 4 fix: persiste direto no _prefs sem chamar save(), evitando
  /// o push desnecessário de volta ao servidor logo após o pull.
  /// Bug 6 fix: restaura também o DayData (histórico diário).
  Future<bool> syncFromServer() async {
    if (authToken == null) return true;
    final result = await AuthService.pullData(token: authToken!);
    if (!result.success || result.data == null) return result.success;
    try {
      final map = result.data!;
      tasks = (map['tasks'] as List? ?? [])
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      metas = (map['metas'] as List? ?? [])
          .map((e) => Meta.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      sleep = SleepData.fromJson(
        map['sleep'] != null ? Map<String, dynamic>.from(map['sleep']) : null,
      );
      isDark = (map['theme'] as String? ?? 'dark') == 'dark';
      focusSeconds = (map['focusSeconds'] as num?)?.toInt() ?? 0;
      userName = map['userName'] as String? ?? userName;
      notifPrefs = NotificationPrefs.fromJson(
        map['notifPrefs'] != null
            ? Map<String, dynamic>.from(map['notifPrefs'])
            : null,
      );

      // Bug 6 fix: restaura o histórico diário (DayData) recebido do servidor
      final dayDataMap = map['dayData'] as Map<String, dynamic>?;
      if (dayDataMap != null) {
        for (final entry in dayDataMap.entries) {
          if (entry.key.startsWith(_kDayPrefix) && entry.value is String) {
            await _prefs.setString(entry.key, entry.value as String);
          }
        }
      }

      // Persiste o estado principal direto no _prefs (sem chamar save())
      // para não disparar um syncToServer() logo após o pull (bug 4)
      final stateMap = {
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'metas': metas.map((m) => m.toJson()).toList(),
        'sleep': sleep.toJson(),
        'theme': isDark ? 'dark' : 'light',
        'focusSeconds': focusSeconds,
        'userName': userName,
        'notifPrefs': notifPrefs.toJson(),
      };
      await _prefs.setString(_kStateKey, jsonEncode(stateMap));
      notifyListeners();
      unawaited(_rescheduleNotifications());
    } catch (_) {
      // dados do servidor corrompidos: mantém estado local
    }
    return true;
  }

  // ── ONBOARDING ──
  Future<void> completeOnboarding(String name) async {
    userName = name;
    onboardingDone = true;
    await _prefs.setBool(_kOnboardingKey, true);
    await save();
    // Atualiza o nome no servidor (cadastro usa email como nome temporário)
    if (authToken != null) {
      unawaited(AuthService.updateName(token: authToken!, nome: name));
    }
  }

  /// Atualiza o nome do usuário localmente e no servidor.
  Future<void> updateUserName(String name) async {
    userName = name;
    await save();
    if (authToken != null) {
      unawaited(AuthService.updateName(token: authToken!, nome: name));
    }
  }

  // ── THEME ──
  Future<void> toggleTheme() async {
    isDark = !isDark;
    await save();
  }

  // ── TASKS ──
  bool taskMatchesDate(Task t, DateTime date) => t.recurrence.matchesDate(date);

  List<Task> getTasksForDate(DateTime date) =>
      tasks.where((t) => taskMatchesDate(t, date)).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  List<Task> get todayTasks => getTasksForDate(DateTime.now());

  Future<void> toggleTask(int id) async {
    final t = tasks.firstWhere((x) => x.id == id);
    t.done = !t.done;
    await save();
  }

  /// Marca uma tarefa como concluída (idempotente). Usado pelo botão
  /// "Concluir" da notificação quando o app está aberto em primeiro plano,
  /// para refletir a mudança feita pelo NotificationService na hora.
  Future<void> markTaskDone(int id) async {
    final idx = tasks.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    if (tasks[idx].done) return; // já estava concluída, evita save() à toa
    tasks[idx].done = true;
    await save();
  }

  Future<void> addTask(Task task) async {
    tasks.add(task);
    await save();
  }

  Future<void> updateTask(Task updated) async {
    final idx = tasks.indexWhere((x) => x.id == updated.id);
    if (idx >= 0) tasks[idx] = updated;
    await save();
  }

  Future<void> deleteTask(int id) async {
    tasks.removeWhere((x) => x.id == id);
    await save();
  }

  // ── METAS ──
  Future<void> addMeta(Meta meta) async {
    metas.add(meta);
    await save();
  }

  Future<void> updateMetaFields(Meta updated) async {
    final idx = metas.indexWhere((x) => x.id == updated.id);
    if (idx >= 0) {
      final m = metas[idx];
      m.name = updated.name;
      m.type = updated.type;
      m.target = updated.target;
      m.unit = updated.unit;
      m.color = updated.color;
    }
    await save();
  }

  Future<void> deleteMeta(int id) async {
    metas.removeWhere((x) => x.id == id);
    for (final t in tasks) {
      if (t.linkedMeta == id) t.linkedMeta = null;
    }
    await save();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Check-in de meta tipo habit (toggle) ou count (sempre soma).
  Future<void> checkIn(int metaId) async {
    final m = metas.firstWhere((x) => x.id == metaId);
    final todayKey = _fmtDate(DateTime.now());

    if (m.type == MetaType.habit) {
      if (m.checkins[todayKey] == true) {
        m.checkins.remove(todayKey);
        m.current = (m.current - 1).clamp(0, double.infinity);
      } else {
        m.checkins[todayKey] = true;
        m.current = (m.current + 1).clamp(0, m.target);
        _recalcStreak(m);
      }
    } else {
      final cur = (m.checkins[todayKey] as num?)?.toInt() ?? 0;
      m.checkins[todayKey] = cur + 1;
      m.current = (m.current + 1).clamp(0, m.target);
      _recalcStreak(m);
    }
    await save();
  }

  void _recalcStreak(Meta m) {
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final key = _fmtDate(d);
      if (m.checkins[key] != null && m.checkins[key] != false) {
        streak++;
      } else {
        break;
      }
    }
    m.streak = streak;
  }

  /// Histórico dos últimos 7 dias de check-in (pra exibir bolinhas).
  List<({String key, String label, bool done, bool isToday})> getCheckinHistory(Meta m) {
    const dayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final today = DateTime.now();
    final todayKey = _fmtDate(today);
    final result = <({String key, String label, bool done, bool isToday})>[];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = _fmtDate(d);
      final dow = d.weekday % 7;
      final done = m.checkins[key] != null && m.checkins[key] != false;
      result.add((key: key, label: dayLabels[dow], done: done, isToday: key == todayKey));
    }
    return result;
  }

  /// Registra tempo de foco (timer) numa meta tipo "hours".
  Future<void> addFocusSeconds(int metaId, int secs) async {
    if (secs <= 0) return;
    final m = metas.firstWhere((x) => x.id == metaId);
    m.focusSecs = (m.focusSecs) + secs;
    if (m.type == MetaType.hours) {
      m.current = (m.current + secs / 3600).clamp(0, m.target);
    }
    focusSeconds = focusSeconds + secs;
    await save();
  }

  // ── DAY DATA (histórico por dia, gravado separadamente como no app original) ──
  DayData getDayData(String dateKey) {
    final raw = _prefs.getString(_kDayPrefix + dateKey);
    if (raw == null) return DayData();
    try {
      return DayData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DayData();
    }
  }

  Future<void> saveDayData(String dateKey, DayData data) async {
    await _prefs.setString(_kDayPrefix + dateKey, jsonEncode(data.toJson()));
    notifyListeners();
  }

  /// Sono REGISTRADO de hoje (DayData de hoje), com fallback para o padrão
  /// configurado em Config caso o usuário ainda não tenha registrado nada.
  /// Isso evita que editar o sono de um dia específico altere o padrão global.
  SleepData getTodaySleep() {
    final key = fmtDateKey(DateTime.now());
    final today = getDayData(key);
    return today.sleep ?? sleep;
  }

  /// Atualiza só o horário de dormir OU de acordar de HOJE, preservando o
  /// outro valor já registrado (ou o padrão, se ainda não houver registro).
  /// Nunca mexe no padrão global `sleep` — só no DayData de hoje.
  Future<void> setTodaySleepField({String? start, String? end}) async {
    final key = fmtDateKey(DateTime.now());
    final today = getDayData(key);
    final current = today.sleep ?? sleep;
    today.sleep = SleepData(
      start: start ?? current.start,
      end: end ?? current.end,
    );
    await saveDayData(key, today);
  }

  /// Atualiza o padrão global de sono (usado só na tela de Configurações).
  Future<void> setDefaultSleep(String start, String end) async {
    sleep = SleepData(start: start, end: end);
    await save();
  }

  /// Define (ou remove, com null) a foto de perfil já cortada.
  /// Apaga o arquivo anterior do armazenamento interno, se houver, para
  /// não acumular imagens órfãs a cada troca de foto.
  Future<void> setAvatarPath(String? newPath) async {
    final oldPath = avatarPath;
    avatarPath = newPath;
    await save();
    if (oldPath != null && oldPath != newPath) {
      try {
        final f = File(oldPath);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // não é crítico se a limpeza falhar
      }
    }
  }

  String fmtDateKey(DateTime d) => _fmtDate(d);

  // ── DATA MANAGEMENT ──
  Future<void> clearAllData() async {
    await _prefs.clear();
    tasks = [];
    metas = [];
    sleep = SleepData();
    isDark = true;
    focusSeconds = 0;
    userName = '';
    avatarPath = null;
    authToken = null;
    notifPrefs = NotificationPrefs();
    onboardingDone = false;
    welcomeAssistantDone = false;
    isFounder = false;
    founderPosition = null;
    emailVerified = false;
    notifyListeners();
    unawaited(NotificationService.instance.cancelAll());
  }

  /// Sai da conta: limpa só o token. Onboarding e welcome assistant
  /// ficam marcados — na próxima vez que logar vai direto pro app.
  Future<void> logout() async {
    authToken = null;
    await _secureStorage.delete(key: _kTokenKey);
    notifyListeners();
  }

  /// Exclui a conta: deleta no servidor e limpa dados locais.
  /// Mantém onboardingDone/welcomeAssistantDone para não mostrar
  /// onboarding de novo caso o usuário se recadastre no mesmo aparelho.
  Future<void> deleteAccount() async {
    final token = authToken;
    if (token != null) {
      // Deleta no servidor primeiro — o overlay segura o usuário esperando
      await AuthService.deleteAccountOnServer(token: token);
    }
    // Limpa dados locais depois que o servidor confirmou
    await _clearAccountData();
  }

  /// Limpa todos os dados da conta mas preserva flags de onboarding.
  Future<void> _clearAccountData() async {
    tasks = [];
    metas = [];
    sleep = SleepData();
    isDark = true;
    focusSeconds = 0;
    userName = '';
    avatarPath = null;
    authToken = null;
    notifPrefs = NotificationPrefs();
    isFounder = false;
    founderPosition = null;
    emailVerified = false;
    // Remove dados da conta do storage
    await _secureStorage.delete(key: _kTokenKey);
    await _prefs.remove(_kStateKey);
    await _prefs.remove(_kFounderKey);
    await _prefs.remove(_kFounderPosKey);
    await _prefs.remove(_kEmailVerifiedKey);
    // Remove histórico de dias
    final keys = _prefs.getKeys().where((k) => k.startsWith(_kDayPrefix)).toList();
    for (final k in keys) await _prefs.remove(k);
    // NÃO remove _kOnboardingKey nem _kWelcomeAssistantKey
    notifyListeners();
    unawaited(NotificationService.instance.cancelAll());
  }

  Map<String, dynamic> exportJson() {
    // Bug 5 fix: avatarPath é caminho local — não sincronizar com o servidor.
    // Bug 6 fix: inclui DayData (notas, dots, sono por dia) no payload de sync.
    final dayDataMap = <String, dynamic>{};
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_kDayPrefix)) {
        final raw = _prefs.getString(key);
        if (raw != null) dayDataMap[key] = raw; // já é JSON string
      }
    }
    return {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'metas': metas.map((m) => m.toJson()).toList(),
      'sleep': sleep.toJson(),
      'theme': isDark ? 'dark' : 'light',
      'focusSeconds': focusSeconds,
      'userName': userName,
      'notifPrefs': notifPrefs.toJson(),
      'dayData': dayDataMap, // histórico diário completo
    };
  }

  int get estimatedSizeBytes => jsonEncode(exportJson()).length;
}
