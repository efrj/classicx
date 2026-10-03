# ClassicX

Demonstração de uma rede social inspirada no X, para estudo de Classic ASP/VBScript com MVC, MariaDB, Bootstrap 5.3 e Alpine.js.

## Executar

```sh
docker compose -f infra/docker-compose.yml up -d
```

Abra http://localhost:8000. O AXONASP 2.3.24 está fixado por digest no Compose e usa o servidor HTTP nativo, porta interna 80, com `/app` como web root. O `Caddyfile` antigo foi preservado como referência e não é montado no container atual.

O banco usa `infra/dbdata`. O script `infra/database_setup.sql` é executado automaticamente **somente na inicialização de um diretório de dados vazio**. Não execute esse script manualmente contra um banco existente: ele contém `DROP TABLE`. O banco existente não foi reinicializado durante as correções.

Credenciais locais de demonstração, usadas também quando `infra/.env` não existe: banco `bd_classicx`, usuário/senha `classicx`. A aplicação abre automaticamente a conta de demonstração 1. O menu permite trocar de conta; “Reset demo account” retorna à conta inicial. Isso não é autenticação para usuários reais.

## Publicar

Copie `infra/.env.example` para `infra/.env` e ajuste host, portas e senhas antes do primeiro `docker compose up`. O Compose lê esse arquivo porque ele fica na mesma pasta do `docker-compose.yml`. Sem o arquivo, o ambiente local continua em `http://localhost:8000`, com o RustFS público em `http://localhost:9000` e o banco no host interno `db`. Depois de mudar o `.env`, rode o mesmo `up -d` para os containers receberem os valores novos.

`CLASSICX_RUSTFS_PUBLIC_URL` é o endereço que o navegador usa para baixar as imagens. Aponte para o RustFS, por exemplo `http://SEU_IP:9000`. Se esse endereço for o próprio ClassicX, o caminho `/uploads` volta para a aplicação e o redirecionamento se repete. URLs já gravadas no banco permanecem com o host antigo; os uploads novos usam a URL configurada. A coluna `image_url` aceita 255 caracteres.

`MYSQL_*` e `CLASSICX_DB_*` precisam concordar. Essas senhas do MariaDB só são criadas na primeira inicialização de `infra/dbdata`. Para trocar a senha de um volume que já existe, altere o usuário no banco e depois atualize o `.env`:

```sh
docker exec -it classicx_db mariadb -uroot -p
ALTER USER 'classicx'@'%' IDENTIFIED BY 'nova-senha';
ALTER USER 'root'@'localhost' IDENTIFIED BY 'nova-senha-root';
```

No VPS, publique o banco e o console do RustFS só em `127.0.0.1` (`DB_BIND` e `RUSTFS_CONSOLE_BIND`) e troque `RUSTFS_ACCESS_KEY` e `RUSTFS_SECRET_KEY`. Senhas com `$`, aspas ou `;` quebram a interpolação do Compose ou a string ODBC. O arquivo `infra/axonasp.toml` não é a conexão da aplicação.

Em um servidor novo, depois que o RustFS subir, crie o bucket público:

```sh
python3 infra/init_rustfs.py
```

O script lê `infra/.env`. A chave padrão `rustfsadmin` existe só para o ambiente local.

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

O primeiro teste cobre páginas, 40 refreshes, 80 leituras simultâneas, entradas inválidas, CSRF, posts/respostas, reações, favoritos, autorização de exclusão e curtidas concorrentes. Cria posts temporários e os remove no final. `CLASSICX_URL` muda a URL base. Os testes que consultam o MariaDB leem `MYSQL_USER`, `MYSQL_PASSWORD` e `MYSQL_DATABASE` de `infra/.env`, com os padrões locais se o arquivo não existir.

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
- Para exposição pública, use `infra/.env` para senhas, portas e a URL do RustFS. Ainda faltam autenticação real, HTTPS, backups, migrações incrementais, limites de uso e uma configuração de erros adequada. O modo de depuração está habilitado para estudo.
- Testes de integração e verificações visuais cobrem os fluxos descritos, não garantem ausência de todos os defeitos do runtime.

## Créditos

MVC baseado em [Sane, de Dave Canfield](https://github.com/davecan/Sane), que declara GPLv3. Runtime [G3Pix AxonASP Server](https://github.com/guimaraeslucas/axonasp), de Lucas Guimarães / G3Pix. Consulte as licenças originais antes de redistribuir. Bootstrap e Alpine.js mantêm suas respectivas licenças.
