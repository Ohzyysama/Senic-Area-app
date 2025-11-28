import router from '@ohos.router';
import http from '@ohos.net.http';
import { common } from '@kit.AbilityKit';

// 类型定义
interface LoginRequestData {
  username: string;
  password: string;
}

interface LoginResponseData {
  userId: number;
  token: string;
  nickName: string;
  avatar: string;
}
// 修改响应接口定义
interface LoginResponse {
  success: boolean;    // 关键修改
  message: string;
  data: LoginResponseData;
}

interface StoredUserData {
  userId: number;
  token: string;
  nickName: string;
  avatar: string;
}

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State serverIP: string = ''

  // 后端API地址 - 根据实际情况修改
  private httpRequest: http.HttpRequest = http.createHttp();

  private async loadServerIP() {
    this.serverIP = await this.getServerIP();
    console.log('加载的服务器IP:', this.serverIP);
  }

  private async getServerIP(): Promise<string> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      const ipValue = await resourceMgr.getString($r('app.string.ip').id);
      return ipValue;
    } catch (error) {
      console.error('获取服务器IP失败:', error);
      return 'localhost:8080';
    }
  }

  aboutToAppear(): void {
    this.loadServerIP()
  }

  build() {
    Column() {
      // 标题
      Text('用户登录')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 50 });

      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#FF6B35')
          .margin({ bottom: 20 })
          .width('80%')
          .textAlign(TextAlign.Center)
      }

      // 用户名输入框
      TextInput({ placeholder: '请输入用户名', text: this.username })
        .width('80%')
        .height(50)
        .padding(10)
        .margin({ bottom: 20 })
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .onChange((value: string) => {
          this.username = value;
          this.errorMessage = '';
        });

      // 密码输入框
      TextInput({ placeholder: '请输入密码', text: this.password })
        .width('80%')
        .height(50)
        .padding(10)
        .margin({ bottom: 40 })
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value;
          this.errorMessage = '';
        });

      // 登录按钮
      Button('登录', { type: ButtonType.Capsule, stateEffect: true })
        .width('80%')
        .height(50)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .fontSize(18)
        .margin({ bottom: 20 })
        .enabled(!this.isLoading && this.username !== '' && this.password !== '')
        .onClick(() => {
          this.handleLogin();
        });

      // 注册链接
      Row({ space: 5 }) {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor('#666666')
        Text('立即注册')
          .fontSize(14)
          .fontColor('#007DFF')
          .decoration({ type: TextDecorationType.Underline })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Register'
            });
          })
      }
      .margin({ bottom: 30 })

      // 加载中状态
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
          Text('登录中...')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 10 })
        }
        .margin({ top: 20 })
      }

      // 测试用户快速登录
      Text('测试用户快速登录')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 40, bottom: 10 })

      Row({ space: 10 }) {
        Button('用户1')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#E6F2FF')
          .fontColor('#007DFF')
          .fontSize(12)
          .onClick(() => {
            this.username = 'testuser1';
            this.password = '123456';
          })

        Button('用户2')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#E6F2FF')
          .fontColor('#007DFF')
          .fontSize(12)
          .onClick(() => {
            this.username = 'testuser2';
            this.password = '123456';
          })

        Button('用户3')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#E6F2FF')
          .fontColor('#007DFF')
          .fontSize(12)
          .onClick(() => {
            this.username = 'testuser3';
            this.password = '123456';
          })
      }
      .margin({ bottom: 20 })
      Row(){
        Button('测试进入')
          .onClick(() => {
            router.pushUrl({url : 'pages/Index'})
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#F5F5F5')
  }

  // 在 handleLogin 方法中修改
  private async handleLogin() {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMessage = '用户名和密码不能为空';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const loginData: LoginRequestData = {
        username: this.username.trim(),
        password: this.password.trim()
      };

      console.log('http://' + `${this.serverIP}` + '/api/auth/login')

      // 建议同时修改URL路径
      const response: http.HttpResponse = await this.httpRequest.request(
        'http://' + `${this.serverIP}` + '/api/auth/login', // 修改路径
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify(loginData)
        }
      );

      console.log('登录响应状态:', response.responseCode);

      if (response.responseCode === 200) {
        const result: LoginResponse = JSON.parse(response.result.toString()) as LoginResponse;

        console.log('登录成功:', result.success);
        if (result.success === true) {  // 关键修改：判断 success
          console.log('111111111')
          const userData: LoginResponseData = result.data;
          this.saveUserData(userData);

          router.replaceUrl({
            url: 'pages/Index'
          }).catch((err: Error) => {
            console.error('跳转失败: ' + JSON.stringify(err));
          });
        } else {
          this.errorMessage = result.message || '登录失败';
        }
      } else {
        this.errorMessage = `网络错误: ${response.responseCode}`;
      }
    } catch (error) {
      console.error('登录请求失败:', error);
      if (error instanceof Error) {
        this.errorMessage = `网络连接失败: ${error.message}`;
      } else {
        this.errorMessage = '网络连接失败，请检查服务器地址';
      }
    } finally {
      this.isLoading = false;
    }
  }

  // 保存用户数据到本地
  private saveUserData(userData: LoginResponseData) {
    try {
      console.log('保存用户数据:', userData);

      // 保存到应用存储
      AppStorage.setOrCreate('userToken', userData.token);

      const storedUserInfo: StoredUserData = {
        userId: userData.userId,
        token: userData.token,
        nickName: userData.nickName,
        avatar: userData.avatar
      };

      AppStorage.setOrCreate('userInfo', storedUserInfo);

    } catch (error) {
      console.error('保存用户数据失败:', error);
    }
  }
}