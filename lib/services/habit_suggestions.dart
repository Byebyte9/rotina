import '../models/meta.dart';
import '../models/recurrence.dart';
import '../models/task.dart';

/// Respostas do mini-questionário do assistente de boas-vindas.
/// Espelha as perguntas feitas no wizard de boas-vindas (ver
/// `welcome_assistant.dart`).
class RoutineProfile {
  String wakeTime; // 'HH:mm'
  String sleepTime; // 'HH:mm'
  String? focusPeriod; // 'manha' | 'tarde' | 'noite'

  RoutineProfile({
    this.wakeTime = '07:00',
    this.sleepTime = '23:00',
    this.focusPeriod,
  });
}

/// Uma tarefa sugerida, criada já vinculada à meta da sugestão (se houver).
class SuggestedTask {
  final String name;
  final String time; // 'HH:mm'
  final TaskWeight weight;
  final List<String> recurDays; // dias da semana '0'-'6' (0=domingo)

  const SuggestedTask({
    required this.name,
    required this.time,
    this.weight = TaskWeight.medium,
    this.recurDays = const ['0', '1', '2', '3', '4', '5', '6'],
  });
}

/// Uma sugestão de meta, com 0+ tarefas associadas que serão criadas
/// já vinculadas a ela (linkedMeta) caso o usuário aceite a sugestão.
class SuggestedMeta {
  final String name;
  final MetaType type;
  final double target;
  final String unit;
  final MetaColor color;
  final List<SuggestedTask> tasks;

  const SuggestedMeta({
    required this.name,
    required this.type,
    required this.target,
    required this.unit,
    this.color = MetaColor.green,
    this.tasks = const [],
  });
}

/// Hábito "extra" oferecido na etapa de ampliação do dia ("quer ampliar
/// mais seu dia?"). Coisas que a pessoa provavelmente não citou nas
/// respostas do questionário, mas que podem somar à rotina — ex: skincare,
/// leitura. [meta] é opcional: alguns hábitos viram só uma tarefa solta
/// (sem meta de acompanhamento), outros já criam uma metinha tipo hábito.
class ExtraHabit {
  final String id;
  final String label;
  final String emoji;
  final SuggestedTask task;
  final SuggestedMeta? meta; // null = entra só como tarefa solta, sem meta

  const ExtraHabit({
    required this.id,
    required this.label,
    required this.emoji,
    required this.task,
    this.meta,
  });
}

/// Categoria de hábitos exibida como card selecionável no assistente.
class HabitCategory {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final List<SuggestedMeta> metas;

  /// Hábitos extras relacionados a esta categoria, oferecidos na etapa de
  /// ampliação somente se esta categoria foi escolhida.
  final List<ExtraHabit> categoryExtras;

  const HabitCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.metas,
    this.categoryExtras = const [],
  });
}

/// Catálogo de categorias oferecidas pelo assistente. As sugestões de
/// horário dos hábitos de sono usam o [RoutineProfile] informado pelo
/// usuário (ver [HabitCategoryCatalog.build]).
class HabitCategoryCatalog {
  static List<HabitCategory> build(RoutineProfile profile) {
    return [
      HabitCategory(
        id: 'saude',
        label: 'Saúde e corpo',
        emoji: '💪',
        description: 'Movimento, água e alimentação no dia a dia.',
        metas: [
          const SuggestedMeta(
            name: 'Atividade física',
            type: MetaType.count,
            target: 4,
            unit: 'vezes/semana',
            color: MetaColor.orange,
            tasks: [
              SuggestedTask(
                name: 'Exercitar-se',
                time: '07:30',
                weight: TaskWeight.heavy,
                recurDays: ['1', '3', '5'],
              ),
            ],
          ),
          const SuggestedMeta(
            name: 'Beber mais água',
            type: MetaType.habit,
            target: 1,
            unit: 'dia',
            color: MetaColor.blue,
            tasks: [
              SuggestedTask(name: 'Beber água', time: '10:00', weight: TaskWeight.light),
            ],
          ),
        ],
        categoryExtras: const [
          ExtraHabit(
            id: 'skincare',
            label: 'Skincare',
            emoji: '🧴',
            task: SuggestedTask(name: 'Skincare', time: '21:45', weight: TaskWeight.light),
          ),
          ExtraHabit(
            id: 'alongamento',
            label: 'Alongamento',
            emoji: '🤸',
            task: SuggestedTask(name: 'Alongar-se', time: '07:15', weight: TaskWeight.light),
            meta: SuggestedMeta(
              name: 'Alongamento',
              type: MetaType.count,
              target: 5,
              unit: 'vezes/semana',
              color: MetaColor.orange,
            ),
          ),
        ],
      ),
      HabitCategory(
        id: 'foco',
        label: 'Foco e produtividade',
        emoji: '🎯',
        description: 'Blocos de trabalho focado e organização do dia.',
        metas: [
          SuggestedMeta(
            name: 'Tempo de foco',
            type: MetaType.hours,
            target: 10,
            unit: 'horas/semana',
            color: MetaColor.purple,
            tasks: [
              SuggestedTask(
                name: 'Bloco de foco',
                time: profile.focusPeriod == 'noite'
                    ? '19:30'
                    : profile.focusPeriod == 'tarde'
                        ? '14:00'
                        : '09:00',
                weight: TaskWeight.heavy,
                recurDays: ['1', '2', '3', '4', '5'],
              ),
            ],
          ),
          const SuggestedMeta(
            name: 'Planejar o dia',
            type: MetaType.habit,
            target: 1,
            unit: 'dia',
            color: MetaColor.gold,
            tasks: [
              SuggestedTask(name: 'Planejar tarefas do dia', time: '08:30', weight: TaskWeight.light),
            ],
          ),
        ],
        categoryExtras: const [
          ExtraHabit(
            id: 'revisar_semana',
            label: 'Revisão semanal',
            emoji: '📋',
            task: SuggestedTask(
              name: 'Revisar a semana',
              time: '19:00',
              weight: TaskWeight.medium,
              recurDays: ['0'],
            ),
          ),
        ],
      ),
      HabitCategory(
        id: 'sono',
        label: 'Sono melhor',
        emoji: '🌙',
        description: 'Rotina noturna para dormir e acordar com mais qualidade.',
        metas: [
          SuggestedMeta(
            name: 'Dormir no horário',
            type: MetaType.habit,
            target: 1,
            unit: 'dia',
            color: MetaColor.blue,
            tasks: [
              SuggestedTask(
                name: 'Desligar telas e ir dormir',
                time: profile.sleepTime,
                weight: TaskWeight.medium,
              ),
              SuggestedTask(
                name: 'Acordar',
                time: profile.wakeTime,
                weight: TaskWeight.light,
              ),
            ],
          ),
        ],
        categoryExtras: const [
          ExtraHabit(
            id: 'sem_telas',
            label: 'Sem telas antes de dormir',
            emoji: '📵',
            task: SuggestedTask(name: 'Guardar o celular', time: '22:30', weight: TaskWeight.light),
          ),
        ],
      ),
      HabitCategory(
        id: 'mente',
        label: 'Mente e bem-estar',
        emoji: '🧘',
        description: 'Pausas, respiração e momentos sem pressa.',
        metas: [
          const SuggestedMeta(
            name: 'Mindfulness',
            type: MetaType.count,
            target: 5,
            unit: 'vezes/semana',
            color: MetaColor.green,
            tasks: [
              SuggestedTask(name: 'Meditar 10 min', time: '07:00', weight: TaskWeight.light),
            ],
          ),
          const SuggestedMeta(
            name: 'Diário/reflexão',
            type: MetaType.habit,
            target: 1,
            unit: 'dia',
            color: MetaColor.gold,
            tasks: [
              SuggestedTask(name: 'Anotar reflexão do dia', time: '21:30', weight: TaskWeight.light),
            ],
          ),
        ],
        categoryExtras: const [
          ExtraHabit(
            id: 'gratidao',
            label: 'Gratidão',
            emoji: '🙏',
            task: SuggestedTask(name: 'Anotar 3 coisas boas do dia', time: '21:00', weight: TaskWeight.light),
          ),
        ],
      ),
      HabitCategory(
        id: 'organizacao',
        label: 'Organização',
        emoji: '🗂️',
        description: 'Casa, finanças e tarefas do cotidiano sob controle.',
        metas: [
          const SuggestedMeta(
            name: 'Organizar espaço',
            type: MetaType.count,
            target: 3,
            unit: 'vezes/semana',
            color: MetaColor.orange,
            tasks: [
              SuggestedTask(
                name: 'Organizar um cômodo/área',
                time: '18:30',
                weight: TaskWeight.medium,
                recurDays: ['1', '3', '5'],
              ),
            ],
          ),
        ],
        categoryExtras: const [
          ExtraHabit(
            id: 'financas',
            label: 'Controle financeiro',
            emoji: '💰',
            task: SuggestedTask(
              name: 'Revisar gastos do dia',
              time: '20:30',
              weight: TaskWeight.light,
            ),
            meta: SuggestedMeta(
              name: 'Controle financeiro',
              type: MetaType.habit,
              target: 1,
              unit: 'dia',
              color: MetaColor.gold,
            ),
          ),
        ],
      ),
    ];
  }

  /// Hábitos "variados" oferecidos na etapa de ampliação independentemente
  /// das categorias escolhidas — coisas que a pessoa pode não ter pensado
  /// em fazer, de áreas que ela talvez nem tenha selecionado antes.
  static List<ExtraHabit> variedExtras() {
    return const [
      ExtraHabit(
        id: 'leitura',
        label: 'Ler um livro',
        emoji: '📖',
        task: SuggestedTask(name: 'Ler 10 páginas', time: '21:00', weight: TaskWeight.light),
        meta: SuggestedMeta(
          name: 'Leitura',
          type: MetaType.count,
          target: 5,
          unit: 'vezes/semana',
          color: MetaColor.purple,
        ),
      ),
      ExtraHabit(
        id: 'tempo_familia',
        label: 'Tempo com família/amigos',
        emoji: '👨‍👩‍👧',
        task: SuggestedTask(
          name: 'Tempo de qualidade com família/amigos',
          time: '19:30',
          weight: TaskWeight.medium,
          recurDays: ['0', '6'],
        ),
      ),
      ExtraHabit(
        id: 'ar_livre',
        label: 'Tempo ao ar livre',
        emoji: '🌳',
        task: SuggestedTask(name: 'Sair para tomar um ar', time: '17:00', weight: TaskWeight.light),
      ),
      ExtraHabit(
        id: 'novo_hobby',
        label: 'Praticar um hobby',
        emoji: '🎨',
        task: SuggestedTask(
          name: 'Tempo de hobby',
          time: '20:00',
          weight: TaskWeight.light,
          recurDays: ['2', '4'],
        ),
      ),
    ];
  }
}
