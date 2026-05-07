# Terraform Infrastructure Generator — README

> 搭配 **`index.html`** 視覺化產生器使用：在瀏覽器開啟 `index.html`，填入參數、勾選元件，點擊「產生完整 Terraform 設定」後即可複製所有 `.tf` 檔案內容，貼回本目錄直接部署。

---

## 目錄結構

```
terraform/
├── index.html                  # 視覺化設定產生器（瀏覽器直接開啟）
├── README.md                   # 本文件
├── main.tf                     # 入口點，呼叫所有 modules
├── variables.tf                # 所有變數定義
├── outputs.tf                  # 輸出值（URL、Cluster 名稱等）
├── terraform.tfvars.example    # 變數範本（複製填入真實值）
├── bootstrap.sh                # 首次執行：建立 S3 + DynamoDB
└── modules/
    ├── vpc/                    # VPC + Subnets + NAT Gateway
    ├── eks/                    # EKS Cluster + Node Group + Namespaces
    ├── harbor/                 # Harbor（映像倉庫）
    ├── argocd/                 # ArgoCD（GitOps）+ AppProject + Applications
    ├── kuboard/                # Kuboard K8s Dashboard + GitLab SSO
    ├── elk/                    # Elasticsearch + Logstash + Kibana + Fluent Bit
    ├── monitoring/             # kube-prometheus-stack（Prometheus + Grafana + Alertmanager）
    └── jenkins/                # Jenkins CI/CD + Kubernetes Agent
```

---

## 核心平台一覽

| 服務 | Namespace | Helm Chart | 說明 |
|------|-----------|------------|------|
| Harbor | `harbor` | `harbor/harbor` | 私有映像倉庫，含漏洞掃描 |
| ArgoCD | `argocd` | `argoproj/argo-cd` | GitOps 持續部署 |
| Kuboard | `kuboard` | `kuboard/kuboard` | K8s Web 管理介面 + GitLab SSO |
| ELK Stack | `elk` | `elastic/*` | 集中式日誌（ES + Logstash + Kibana + Fluent Bit）|
| Prometheus / Grafana | `monitoring` | `prometheus-community/kube-prometheus-stack` | 監控 + 告警 |
| **Jenkins** | `jenkins` | `jenkins/jenkins` | **CI/CD Pipeline + Kubernetes 動態 Agent** |

### Jenkins 特性
- **Kubernetes Plugin**：每次 Pipeline 動態起 Pod 作為 Build Agent，用完即銷毀
- **預裝 Plugins**：git、gitlab-plugin、blueocean、docker-workflow、credentials-binding、JCasC
- **JCasC（Configuration as Code）**：透過 Helm values 注入初始設定，不需手動點選
- **Prometheus Metrics**：自動整合 monitoring module 的 Grafana 監控
- **PVC（gp3）**：Jenkins home 目錄持久化，預設 20Gi

---

## 使用流程

### Step 0：用 index.html 產生設定

```
1. 瀏覽器開啟 index.html
2. 填入：Project name / AWS region / Base domain / EKS node 規格
3. 勾選需要的核心平台（Harbor、ArgoCD、Jenkins 等）
4. 選填 SQL / NoSQL / MQ 類型與模式
5. 填入 GitLab 整合資訊與各服務密碼
6. 點擊「產生完整 Terraform 設定」
7. 切換 Tab 複製：main.tf / variables.tf / terraform.tfvars
8. 參考「啟動步驟」Tab 執行部署
```

### Step 1：前置準備

```bash
# 安裝工具
brew install terraform awscli kubectl

# 設定 AWS IAM（非 root）
aws configure
# AWS Access Key ID:     <IAM User Access Key>
# AWS Secret Access Key: <IAM User Secret>
# Default region:        ap-northeast-1
```

### Step 2：Bootstrap — 建立 S3 State 後端（只需一次）

```bash
cd terraform
chmod +x bootstrap.sh

# 修改 bootstrap.sh 內的 BUCKET 名稱後執行
./bootstrap.sh
```

也可手動執行：

```bash
REGION="ap-northeast-1"
BUCKET="your-terraform-state-bucket"

aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"
```

### Step 3：填入變數

```bash
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars，填入所有真實值
# ⚠️  此檔案含有密碼，絕對不可 commit！
```

需填入的 Secrets：

| 變數 | 說明 |
|------|------|
| `harbor_admin_password` | Harbor admin 密碼 |
| `jenkins_admin_password` | Jenkins admin 密碼 |
| `gitlab_kuboard_app_id` | Kuboard GitLab OAuth App ID |
| `gitlab_kuboard_secret` | Kuboard GitLab OAuth Secret |
| `gitlab_grafana_client_id` | Grafana GitLab OAuth Client ID |
| `gitlab_grafana_client_secret` | Grafana GitLab OAuth Client Secret |
| `slack_webhook_url` | Alertmanager Slack 通知（選填）|

### Step 4：初始化

```bash
terraform init
```

### Step 5：預覽變更

```bash
terraform validate
terraform plan -out=tfplan
```

### Step 6：一鍵部署全部資源

```bash
terraform apply tfplan
# 首次約 25-35 分鐘（EKS 建立最久）
```

或逐步部署（依 depends_on 順序）：

```bash
terraform apply -target=module.vpc
terraform apply -target=module.eks
terraform apply -target=module.harbor
terraform apply -target=module.argocd
terraform apply -target=module.kuboard
terraform apply -target=module.elk
terraform apply -target=module.monitoring
terraform apply -target=module.jenkins   # ← 新增
```

### Step 7：取得連線資訊

```bash
# 更新 kubeconfig
$(terraform output -raw kubeconfig_command)

# 查看所有服務 URL
terraform output service_urls

# 確認所有 Pod 正常
kubectl get pods -A
```

輸出範例：
```
service_urls = {
  "argocd"  = "https://argocd.yourdomain.com"
  "grafana" = "https://grafana.yourdomain.com"
  "harbor"  = "https://harbor.yourdomain.com"
  "jenkins" = "https://jenkins.yourdomain.com"
  "kibana"  = "https://kibana.yourdomain.com"
  "kuboard" = "https://kuboard.yourdomain.com"
}
```

---

## 部署順序（depends_on 自動處理）

```
1. module.vpc         → VPC / Subnets / NAT Gateway
2. module.eks         → EKS Cluster / Node Group / Namespaces / StorageClass
3. module.harbor      → Harbor 映像倉庫
4. module.argocd      → ArgoCD + AppProject + Applications
5. module.kuboard     → Kuboard + GitLab SSO
6. module.elk         → ELK Stack（ES + Logstash + Kibana + Fluent Bit）
7. module.monitoring  → Prometheus + Grafana + Alertmanager
8. module.jenkins     → Jenkins + Kubernetes Agent + JCasC        ← 新增
```

---

## index.html 對應關係

`index.html` 產生器的每個區塊，對應本 Terraform 專案的設定：

| index.html 區塊 | 對應 Terraform |
|----------------|----------------|
| 基礎環境參數（Project / Region / Domain）| `variables.tf` 基礎變數 + `backend "s3"` |
| EKS node type / count | `variables.tf` node_* 變數 |
| 核心平台 Toggle（Harbor / ArgoCD / Kuboard / ELK / Monitoring / **Jenkins**）| `main.tf` 各 `module` block |
| SQL 資料庫（MySQL / PostgreSQL / MariaDB）| `modules/mysql` `modules/postgres` `modules/mariadb`（需自建）|
| NoSQL 資料庫（Redis / MongoDB / ...）| `modules/redis` `modules/mongodb` ...（需自建）|
| 訊息佇列（Kafka / RabbitMQ / ...）| `modules/kafka` `modules/rabbitmq` ...（需自建）|
| GitLab 整合 | `variables.tf` gitlab_* 變數 |
| Secrets 設定 | `terraform.tfvars`（sensitive 變數）|
| 啟動步驟 Tab | 本 README Step 1–7 |
| Modules 清單 Tab | 本 README 核心平台一覽表 |

> **提示**：index.html 的「啟動步驟」Tab 會根據你填入的 Project name 與 Region 自動產生對應的 bootstrap 與 apply 指令，與本 README 的 Step 2–7 完全對應。

---

## 常用指令

```bash
# 查看 State 列表
terraform state list

# 查看特定資源
terraform state show module.jenkins.helm_release.jenkins

# 格式化程式碼
terraform fmt -recursive

# 僅銷毀特定 module（謹慎！）
terraform destroy -target=module.jenkins

# 重新部署單一 module
terraform apply -target=module.jenkins

# 查看 Jenkins 初始密碼（若未透過 JCasC 設定）
kubectl exec -n jenkins \
  $(kubectl get pods -n jenkins -l app.kubernetes.io/name=jenkins -o name | head -1) \
  -- cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## .gitignore 建議

```gitignore
# Terraform
terraform.tfvars
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
tfplan

# 產生器輸出（本機使用）
index.html
```

---

## ⚠️ 重要注意事項

- `terraform.tfvars` 含有機密資訊，**絕對不可 commit 進 git**
- SQL / NoSQL / MQ modules 由 `index.html` 產生 module block，但需**自行在 `modules/` 建立對應子目錄**（可參考 `modules/harbor/` 結構）
- Prod 環境建議在重要資源加上 `lifecycle { prevent_destroy = true }`
- 首次 `terraform apply` 約需 **25–35 分鐘**（EKS 建立最久）
- Jenkins PVC 預設 20Gi（gp3），可在 `terraform.tfvars` 調整 `jenkins_storage_size`
