import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:provider/provider.dart';
import 'package:ouroboros_mobile/providers/plans_provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/screens/plan_detail_screen.dart';
import 'package:ouroboros_mobile/widgets/create_plan_modal.dart';
import 'package:ouroboros_mobile/widgets/import_guide_modal.dart';
import 'package:uuid/uuid.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  InAppWebViewController? _webViewController;
  final Completer<InAppWebViewController> _controllerCompleter = Completer<InAppWebViewController>();

  final List<String> _subjectColors = [
    '#ef4444', '#f97316', '#eab308', '#84cc16', '#22c55e', '#14b8a6',
    '#06b6d4', '#3b82f6', '#8b5cf6', '#d946ef', '#f43f5e', '#64748b',
    '#f43f5e', '#be123c', '#9f1239', '#7f1d1d', '#7f1d1d', '#881337',
    '#9d174d', '#a21caf', '#86198f', '#7e22ce', '#6b21a8', '#5b21b6',
    '#4c1d95', '#312e81', '#1e3a8a', '#1e40af', '#1d4ed8', '#2563eb',
    '#3b82f6', '#0284c7', '#0369a1', '#075985', '#0891b2', '#0e7490',
    '#155e75', '#166534', '#14532d', '#16a34a', '#15803d', '#166534'
  ];

  String _cleanSubjectName(String rawName) {
    final stopWords = [' para ', ' - ', ' ('];
    int? firstStopIndex;

    for (final word in stopWords) {
      final index = rawName.indexOf(word);
      if (index != -1) {
        if (firstStopIndex == null || index < firstStopIndex) {
          firstStopIndex = index;
        }
      }
    }

    if (firstStopIndex != null) {
      return rawName.substring(0, firstStopIndex).trim();
    }

    return rawName.trim();
  }

  Future<Plan> _scrapeGuide(String url) async {
    final controller = await _controllerCompleter.future.timeout(const Duration(seconds: 30), onTimeout: () {
      throw Exception('WebView controller not ready within 30 seconds.');
    });
    print('PlansScreen: WebView controller obtido.');
    print('PlansScreen: Iniciando scraping para URL: $url');

    final Map<String, dynamic> headerData = await _extractHeaderAndSubjectLinks(controller, url);
    print('PlansScreen: Header Data extraído: $headerData');

    final List<dynamic> subjectLinksDynamic = headerData['subjectLinks'];
    print('PlansScreen: Tipo de subjectLinksDynamic: ${subjectLinksDynamic.runtimeType}');
    print('PlansScreen: Conteúdo de subjectLinksDynamic: $subjectLinksDynamic');

    final List<Map<String, String>> subjectLinks = subjectLinksDynamic.map((item) => Map<String, String>.from(item)).toList();
    final List<Subject> finalSubjects = [];

    print('PlansScreen: Iniciando extração de matérias. Total: ${subjectLinks.length}');
    for (var i = 0; i < subjectLinks.length; i++) {
      final subjectLink = subjectLinks[i];
      print('PlansScreen: Processando matéria ${i + 1}/${subjectLinks.length}: ${subjectLink['name']} - ${subjectLink['url']}');
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(subjectLink['url']!)));
      final List<Topic> topics = await _extractTopics(controller);
      print('PlansScreen: Matéria ${subjectLink['name']} - Tópicos extraídos: ${topics.length}');
      // Adicionando log detalhado dos tópicos
      try {
        final topicsJson = jsonEncode(topics.map((t) => t.toMap()).toList());
        print('PlansScreen: Tópicos para ${subjectLink['name']}: $topicsJson');
      } catch (e) {
        print('PlansScreen: Erro ao encodar tópicos para JSON: $e');
      }
      
      finalSubjects.add(Subject(
        id: const Uuid().v4(),
        plan_id: '', // Será preenchido depois
        subject: _cleanSubjectName(subjectLink['name']!),
        color: _subjectColors[i % _subjectColors.length],
        topics: topics,
        total_topics_count: topics.length, // Simplificado
        import_source: 'GUIDE',
      ));
    }

    final planId = const Uuid().v4();
    final subjectsWithPlanId = finalSubjects.map((s) => Subject(
      id: s.id, plan_id: planId, subject: s.subject, color: s.color, topics: s.topics, total_topics_count: s.total_topics_count, import_source: s.import_source
    )).toList();

    final plan = Plan(
      id: planId,
      name: headerData['name'] ?? '',
      cargo: headerData['cargo'],
      edital: headerData['edital'],
      banca: headerData['banca'],
      iconUrl: headerData['iconUrl'],
      subjects: subjectsWithPlanId,
    );

    print('PlansScreen: Plano final montado: ${plan.name} com ${plan.subjects?.length ?? 0} matérias.');
    return plan;
  }

  Future<Map<String, dynamic>> _extractHeaderAndSubjectLinks(InAppWebViewController controller, String url) async {
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    await _waitForSelector(
      controller, 
      'div.guias-cabecalho, div.cadernos-agrupamento, div.detalhes-cabecalho', 
      textConditionJs: 'document.querySelector("span.cadernos-colunas-destaque") && !document.querySelector("span.cadernos-colunas-destaque").textContent.includes("{{")'
    );
    
    String getHeaderJs = """ 
      (function() {
        let name = document.querySelector('div.guias-cabecalho-concurso-nome')?.textContent?.trim() || 
                   document.querySelector('div.detalhes-cabecalho-informacoes-texto h1 span:not([class])')?.textContent?.trim() || 
                   document.title.split('-')[0].trim();
        let iconUrl = document.querySelector('div.guias-cabecalho-logo img')?.getAttribute('src') || 
                      document.querySelector('div.detalhes-cabecalho-logotipo img')?.getAttribute('src') || 
                      document.querySelector('img[alt*="logotipo"]')?.getAttribute('src') || '';
        
        let cargo = document.querySelector('span.detalhes-cabecalho-informacoes-orgao')?.textContent?.trim() ||
                    document.querySelector('div.guias-cabecalho-concurso-cargo')?.textContent?.trim() || '';

        let edital = document.querySelector('h2.detalhes-valores')?.textContent?.trim() ||
                     document.querySelector('div.guias-cabecalho-concurso-edital')?.textContent?.trim() || '';

        let banca = '';
        const bancaLabel = Array.from(document.querySelectorAll('span.detalhes-campos')).find(el => el.textContent?.trim() === 'Banca');
        if (bancaLabel && bancaLabel.nextElementSibling) {
            banca = (bancaLabel.nextElementSibling).textContent?.split('(')[0].trim() || '';
        }

        return { name, cargo, edital, iconUrl, banca };
      })();
    """;
    final headerData = await controller.evaluateJavascript(source: getHeaderJs);

    String getLinksJs = """ 
      (function() {
        const links = [];
        let subjectElementsGuia = document.querySelectorAll('div.guia-materia-item');
        console.log('subjectElementsGuia count:', subjectElementsGuia.length);
        if (subjectElementsGuia.length > 0) {
            subjectElementsGuia.forEach(el => {
                const anchor = el.querySelector('h4.guia-materia-item-nome a');
                if (anchor) {
                    const name = anchor.textContent?.trim();
                    const url = anchor.href;
                    if (name && name !== 'Inéditas' && url) {
                        links.push({name: name, url: url});
                    }
                }
            });
        } else {
            let subjectElementsCadernos = document.querySelectorAll('div.cadernos-item');
            console.log('subjectElementsCadernos count:', subjectElementsCadernos.length);
            subjectElementsCadernos.forEach(el => {
                console.log('Processing cadernos-item:', el.outerHTML);
                const nameEl = el.querySelector('span.cadernos-colunas-destaque');
                console.log('nameEl:', nameEl?.outerHTML, 'textContent:', nameEl?.textContent?.trim());
                const anchor = el.querySelector('a.cadernos-ver-detalhes');
                console.log('anchor:', anchor?.outerHTML, 'href:', anchor?.href);
                if (nameEl && anchor) {
                    const name = nameEl.textContent?.trim();
                    const url = anchor.href;
                    if (name && name !== 'Inéditas' && url) {
                        links.push({name: name, url: url});
                    }
                }
            });
        }
        return links;
      })();
    """;
    final linksResult = await controller.evaluateJavascript(source: getLinksJs) as List<dynamic>;
    print('PlansScreen: Links de matérias brutos: $linksResult');
    (headerData as Map<String, dynamic>)['subjectLinks'] = linksResult.map((item) => Map<String, String>.from(item)).toList();

    return headerData;
  }

  Future<List<Topic>> _extractTopics(InAppWebViewController controller) async {
    await _waitForSelector(controller, 'div.caderno-guia-arvore-indice ul', textConditionJs: 'document.querySelector("div.caderno-guia-arvore-indice ul li") != null');
    String getTopicsJs = """ 
      (function() {
        const processLis = (ulElement) => {
            const topics = [];
            if (!ulElement) return topics;
            let lastTopic = null;

            Array.from(ulElement.children).forEach(child => {
                if (child.tagName === 'LI') {
                    const span = child.querySelector(':scope > span');
                    const topicText = span?.textContent?.trim();
                    if (!topicText) return;

                  const questionCountEl = child.querySelector('span.capitulo-questoes > span');
                  let questionCount = 0;
                  if (questionCountEl) {
                      const text = questionCountEl.innerText?.trim().toLowerCase();
                      if (text) {
                          if (text === 'uma questão') {
                              questionCount = 1;
                          } else {
                              const numberString = text.replace(/\D/g, '');
                              if (numberString) {
                                  questionCount = parseInt(numberString, 10);
                              }
                          }
                      }
                  }
                    const newTopic = { 
                        topic_text: topicText, 
                        sub_topics: [], 
                        question_count: questionCount, 
                        is_grouping_topic: false
                    };
                    topics.push(newTopic);
                    lastTopic = newTopic;
                } else if (child.tagName === 'UL' && lastTopic) {
                    lastTopic.sub_topics = processLis(child);
                    lastTopic.is_grouping_topic = lastTopic.sub_topics.length > 0;
                }
            });
            return topics;
        };
        const mainTreeContainer = document.querySelector('div.caderno-guia-arvore-indice ul');
        return processLis(mainTreeContainer);
      })();
    """;
    final topicsResult = await controller.evaluateJavascript(source: getTopicsJs) as List<dynamic>;
    return topicsResult.map((topicMap) => Topic.fromMap(topicMap)).toList();
  }

  Future<void> _waitForSelector(InAppWebViewController controller, String selector, {int timeout = 30000, String? textConditionJs}) async {
    final completer = Completer<void>();
    final stopwatch = Stopwatch()..start();

    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final selectorExists = await controller.evaluateJavascript(source: 'document.querySelector("$selector") != null');
      bool conditionMet = selectorExists == true;

      if (conditionMet && textConditionJs != null) {
        final textConditionResult = await controller.evaluateJavascript(source: textConditionJs);
        conditionMet = textConditionResult == true;
      }

      if (conditionMet) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (stopwatch.elapsedMilliseconds > timeout) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(Exception('Timeout esperando pelo seletor: $selector' + (textConditionJs != null ? ' com condição de texto: $textConditionJs' : '')));
        }
      }
    });

    return completer.future;
  }

  Future<void> _handleImportGuide(String guideUrl) async {
    print('PlansScreen: _handleImportGuide chamado com URL: $guideUrl');
    try {
      final Plan planData = await _scrapeGuide(guideUrl);

      final plansProvider = Provider.of<PlansProvider>(context, listen: false);
      final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);

      Plan? existingPlan = await plansProvider.getPlanByName(planData.name);
      String planId;

      if (existingPlan != null) {
        planId = existingPlan.id;
      } else {
        final newPlan = await plansProvider.addPlan(
          name: planData.name,
          observations: planData.observations,
          cargo: planData.cargo,
          edital: planData.edital,
          banca: planData.banca,
          iconUrl: planData.iconUrl,
        );
        planId = newPlan.id;
      }

      if (planData.subjects != null) {
        final subjectsWithCorrectPlanId = planData.subjects!.map((s) => Subject(
          id: s.id,
          plan_id: planId, // Use o ID do plano recém-criado
          subject: s.subject,
          color: s.color,
          topics: s.topics,
          total_topics_count: s.total_topics_count,
        )).toList();

        for (var subjectData in subjectsWithCorrectPlanId) {
          Subject? existingSubject = await allSubjectsProvider.getSubjectByNameAndPlanId(subjectData.subject, planId);

          if (existingSubject != null) {
            final updatedSubject = Subject(
              id: existingSubject.id,
              plan_id: planId,
              subject: subjectData.subject,
              topics: subjectData.topics,
              color: existingSubject.color, // Keep the existing color
              total_topics_count: subjectData.total_topics_count,
            );
            await allSubjectsProvider.updateSubject(updatedSubject);
          } else {
            final newSubject = Subject(
              id: const Uuid().v4(),
              plan_id: planId,
              subject: subjectData.subject,
              topics: subjectData.topics,
              color: subjectData.color,
              total_topics_count: subjectData.total_topics_count,
            );
            await allSubjectsProvider.addSubject(newSubject);
          }
        }
      }

      await Provider.of<AllSubjectsProvider>(context, listen: false).fetchData();
      await Provider.of<PlansProvider>(context, listen: false).fetchPlans();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plano "${planData.name}" importado com sucesso!')),
      );

    } catch (e) {
      print('PlansScreen: Erro durante a importação do guia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar o guia: $e')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PlansScreen: build chamado.');
    return Stack(
      children: [
        Scaffold(
          body: Consumer<PlansProvider>(
            builder: (context, provider, child) {
              print('PlansScreen Consumer: isLoading=${provider.isLoading}, plans.isEmpty=${provider.plans.isEmpty}');
              if (provider.isLoading && provider.plans.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.plans.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildPlansList(context, provider.plans);
            },
          ),
        ),
        SizedBox(
          width: 0,
          height: 0,
          child: Offstage(
            offstage: true,
            child: InAppWebView(
              onWebViewCreated: (controller) {
                print('PlansScreen: InAppWebView onWebViewCreated chamado.');
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhum plano de estudo encontrado.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const CreatePlanModal();
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crie seu primeiro plano'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            const Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Importar Guia do Tec Concursos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    const Text('Importe um plano de estudos diretamente de um guia do Tec Concursos.'),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ImportGuideModal(onImport: _handleImportGuide);
                            },
                          );
                        },
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Importar Guia'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, List<Plan> plans) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Importar Guia do Tec Concursos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                const Text('Importe um plano de estudos diretamente de um guia do Tec Concursos.'),
                const SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ImportGuideModal(onImport: _handleImportGuide);
                        },
                      );
                    },
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Importar Guia'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanDetailScreen(plan: plan),
                  ),
                );
              },
              child: _buildPlanCard(context, plan),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan) {
    final stats = Provider.of<PlansProvider>(context, listen: false).planStats[plan.id] ?? (subjectCount: 0, topicCount: 0);

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (plan.iconUrl != null && plan.iconUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  plan.iconUrl!,
                  height: 96,
                  width: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.assignment, size: 96, color: Colors.grey),
                ),
              )
            else
              const Icon(Icons.assignment, size: 96, color: Colors.grey),
            Text(
              plan.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Column(
              children: [
                Text('Disciplinas: ${stats.subjectCount}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                Text('Tópicos: ${stats.topicCount}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, plan);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Plan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Você tem certeza que deseja excluir o plano "${plan.name}"? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<PlansProvider>(context, listen: false).deletePlan(plan.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
