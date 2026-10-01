# ClassicX

Demonstração de uma rede social inspirada no X, para estudo de Classic ASP/VBScript com MVC, MariaDB, Bootstrap 5.3 e Alpine.js.

## Executar

```sh
docker compose -f infra/docker-compose.yml up -d
```

Abra http://localhost:8000. O AXONASP 2.3.24 está fixado por digest no Compose e usa o servidor HTTP nativo, porta interna 80, com `/app` como web root. O `Caddyfile` antigo foi preservado como referência e não é montado no container atual.

O banco usa `infra/dbdata`. O script `infra/database_setup.sql` é executado automaticamente **somente na inicialização de um diretório de dados vazio**. Não execute esse script manualmente contra um banco existente: ele contém `DROP TABLE`. O banco existente não foi reinicializado durante as correções.

Credenciais locais de demonstração: banco `bd_classicx`, usuário/senha `classicx`. A aplicação abre automaticamente a conta de demonstração 1. O menu permite trocar de conta; “Reset demo account” retorna à conta inicial. Isso não é autenticação para usuários reais.

## Estrutura

- `app/App/Controllers`: ações explicitamente permitidas, sem executar código recebido em `_A`.
- `app/App/DomainModels`: modelos e repositórios.
- `app/App/Views`: views e parciais compartilhadas.
- `app/App/DAL`: conexão por requisição e transações.
- `app/MVC`: adaptação do framework Sane; `lib.Data.asp` cria comandos ADO parametrizados.
- `app/Content`: Bootstrap/Alpine complementados por CSS e JavaScript próprios.
- `tests`: testes HTTP e integração com o banco local.

## Funcionalidades demonstradas

Feed geral e de contas seguidas; busca; perfil e abas de posts/respostas/curtidas; publicação de texto e upload de imagens para armazenamento de objetos RustFS (S3 na porta 9000) com pré-visualização; respostas; exclusão do próprio post; curtidas; reposts (incluindo perfil); favoritos; seguir/deixar de seguir; notificações e marcação de leitura; troca de conta demonstrativa.

As escritas exigem POST e token CSRF. IDs e conteúdo são validados no servidor. A DAL usa `ADODB.Command` com parâmetros; ações relacionadas usam transação e bloqueio para manter contadores consistentes. Respostas a posts excluídos são preservadas como posts independentes.

## Verificação

Com os containers em execução e Python 3 instalado:

```sh
python3 tests/smoke.py
python3 tests/social.py
```

O primeiro teste cobre páginas, 40 refreshes, 80 leituras simultâneas, entradas inválidas, CSRF, posts/respostas, reações, favoritos, autorização de exclusão e curtidas concorrentes. Cria posts temporários e os remove no final. `CLASSICX_URL` permite mudar a URL base desse teste.

O segundo exige a CLI Docker e os containers locais `classicx_db`/`classicx_web`. Cria duas contas temporárias e verifica seguir, notificação única, leitura, feed Following, repost no perfil e reset da conta. Remove essas contas e seus dados ao concluir.

```sh
docker compose -f infra/docker-compose.yml ps
docker logs --tail 50 classicx_web
```

## Correções de estabilidade

A imagem antiga era `caddy-2.3.21`. O despacho via `ExecuteGlobal` reproduziu respostas 200/500 alternadas; controllers explícitos eliminaram essa reprodução. O teste concorrente revelou também `fatal error: concurrent map writes` em `AxonASP.setupSiteTempDir` do módulo Caddy. A configuração atual usa o HTTP nativo da versão 2.3.24 e passou nos testes simultâneos. O healthcheck consulta uma página ASP real na porta correta.

A versão nova suporta os parâmetros ADO usados pelo projeto. A imagem antiga não substituía `?` no teste de `ADODB.Command`. Não volte ao digest antigo mantendo a DAL atual.

## Limites e próximos passos

Este é um protótipo educacional, não um clone completo nem um serviço pronto para publicação:

- Cadastro, autenticação real, hash de senhas, recuperação de conta e edição de perfil ainda precisam ser implementados. O método legado `Authenticate` não deve ser usado para produção: compara texto com texto.
- Não há mensagens privadas, moderação, rate limiting, paginação/infinite scroll nem busca avançada.
- Trends, Premium e parte dos números iniciais são dados/elementos de demonstração. Os contadores iniciais do seed não necessariamente correspondem às relações existentes.
- O feed Following mostra posts das contas seguidas; não distribui seus reposts como eventos separados.
- CSS, fontes, Alpine, Bootstrap e imagens externas dependem de internet. Não foi implementado funcionamento offline.
- Para exposição pública, substituir credenciais locais, implementar autenticação real e gestão de segredos, HTTPS, backups, migrações incrementais, limites de uso e configuração de erros adequada. O modo de depuração está habilitado para estudo.
- Testes de integração e verificações visuais cobrem os fluxos descritos, não garantem ausência de todos os defeitos do runtime.

## Créditos

MVC baseado em [Sane, de Dave Canfield](https://github.com/davecan/Sane), que declara GPLv3. Runtime [G3Pix AxonASP Server](https://github.com/guimaraeslucas/axonasp), de Lucas Guimarães / G3Pix. Consulte as licenças originais antes de redistribuir. Bootstrap e Alpine.js mantêm suas respectivas licenças.
