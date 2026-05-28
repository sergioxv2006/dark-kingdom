# Dark Kingdom

**Dark Kingdom** é um jogo de plataforma 2D com temática medieval, criado na engine Godot. O projeto inclui movimentos do personagem principal, inimigos com comportamento de patrulha e ataque, plataformas móveis, blocos quebráveis e transição entre cenários.

## Visão Geral

- Engine: Godot 4.6
- Resolução do jogo: 288x208 (modo `canvas_items`)
- Estilo: ação e plataforma 2D
- Temática: medieval / fantasia

## Recursos do Jogo

- Personagem jogável com estados de movimento:
  - caminhar
  - pular
  - agachar
  - atacar com downswing
  - sofrer dano
- Inimigo `Skeleton` com patrulha, detecção de parede, ataque e projéteis lançados (`Spinning Bone`).
- Plataformas móveis que se movem entre pontos definidos.
- Blocos quebráveis que caem e retornam após um tempo.
- Área de fim de fase que carrega o próximo nível.
- Sistema de câmera simples que segue o jogador.

## Controles

Os controles são definidos em `project.godot` e usados no jogo:

- `left` — mover para a esquerda
- `right` — mover para a direita
- `jump` — pular
- `squat` — agachar
- `attack` — atacar com a espada

> No arquivo de configuração do projeto, o `jump` também responde à tecla `Space`.

## Como Executar

1. Abra o projeto no Godot 4.6.
2. Configure a cena principal, se necessário.
3. Execute o jogo diretamente pelo editor.

## Estrutura do Projeto

### Arquivos e Pastas Principais

- `project.godot` — configurações do projeto, incluindo cena principal, entradas e camadas de física.
- `README.md` — documentação do projeto.
- `icon.svg.import` — ícone do projeto importado.

### Pastas de cenário e entidades

- `scene/` — cenas do jogo, como `darkforest.tscn`, `forest.tscn`, `game.tscn`, `tropic.tscn`.
- `entities/` — cenas de entidades reutilizáveis, como inimigos, blocos e o jogador.
- `scripts/` — scripts GDScript que controlam a lógica do jogo.
- `sprites/` — recursos visuais usados pelo jogo.
- `tiles/` — tilesets usados em mapas de terreno e decoração.
- `addons/AsepriteWizard/` — plugin de importação Aseprite para Godot.

### Scripts Importantes

- `scripts/player.gd` — controla o personagem principal e os estados de animação.
- `scripts/skeleton.gd` — controla o inimigo esqueleto, incluindo patrulha e ataque.
- `scripts/spinning_bone.gd` — projétil lançado pelo inimigo.
- `scripts/moving_platform.gd` — movimentação de plataformas.
- `scripts/broken_block.gd` — lógica de blocos quebráveis.
- `scripts/level_end.gd` — transição para o próximo nível.
- `scripts/camera.gd` — lógica de câmera que segue o jogador.

## Comportamento do Personagem

O jogador possui estados bem definidos através de um `enum` e mudanças de animação:

- `idle` — estado parado.
- `walk` — movimentação horizontal.
- `jump` — pulo para cima.
- `fall` — queda.
- `squat` — agachamento com colisão reduzida.
- `downswing` — ataque com espada, capaz de rebater projéteis e acertar inimigos.
- `hurt` — dano sofrido com reinício da cena via timer.

### Regras de combate

- Atacar durante o estado `downswing` causa dano em inimigos no grupo `Enemies`.
- Tocar em inimigos sem atacar faz o jogador entrar em `hurt`.
- A área de ataque (`Hitbox`) pode interceptar projéteis e destruí-los.

## Comportamento dos Inimigos

O inimigo `Skeleton` possui as seguintes funcionalidades:

- patrulha entre paredes e bordas usando `RayCast2D`.
- muda para estado `attack` quando o jogador é detectado.
- dispara um projétil `Spinning Bone` durante a animação de ataque.
- entra em estado `hurt` quando recebe dano.

## Funcionalidades Adicionais

- `Broken Block`: cai e desaparece temporariamente quando o jogador pisa sobre ele.
- `Moving Platform`: movimento repetido entre posições usando `Tween`.
- `Level End`: ao entrar em uma área, o jogo carrega a próxima cena com base na propriedade `next_level`.

## Observações

- O projeto utiliza `GL Compatibility` e renderização `mobile` em Godot.
- Se for necessário atualizar ou modificar entradas de controle, edite a seção `[input]` em `project.godot`.
- Não há licença incluída no repositório; adicione um arquivo `LICENSE` se desejar definir termos de uso.

## Próximos Passos / Melhorias

- adicionar HUD com vida e contagem de pontos;
- implementar múltiplas vidas e sistema de checkpoints;
- adicionar efeitos sonoros e música de fundo;
- criar mais níveis e inimigos variados;
- melhorar a detecção de colisão e o polimento de animações.
