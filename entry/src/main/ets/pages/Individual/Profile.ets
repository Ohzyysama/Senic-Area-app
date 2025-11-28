import router from '@ohos.router';
import http from '@ohos.net.http';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { common } from '@kit.AbilityKit';

// 头像更新请求数据接口
interface AvatarUpdateRequest {
  avatarUrl: string;
}

// 头像更新响应接口
interface AvatarUpdateResponse {
  success: boolean;
  message: string;
  data: null;
}

// 修正后的API响应接口
interface ProfileApiResponse {
  success: boolean;
  message: string;
  data: UserProfileData;
}

// 用户资料数据接口
interface UserProfileData {
  userId: number;
  nickName: string;
  avatar: string;
  phone: string;
  totalPoints: number;
  checkInCount: number;
}

// 用户信息接口
interface UserInfo {
  userId: string;
  nickName: string;
  avatar: string;
  phone: string;
  totalPoints: number;
  checkInCount: number;
}

// 本地存储的用户数据结构
interface StoredUserData {
  userId: string;
  token: string;
  nickName: string;
  avatar: string;
}

@Entry
@Component
struct Profile {
  // 用户数据
  @State userInfo: UserInfo = {
    userId: '',
    nickName: '加载中...',
    avatar: '',
    phone: '',
    totalPoints: 0,
    checkInCount: 0
  };

  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '';
  @State isUploadingAvatar: boolean = false;
  @State serverIP:string = ''

  // 从 AppStorage 同步的用户数据
  @StorageLink('userInfo') storedUserInfo: StoredUserData = {
    userId: '',
    token: '',
    nickName: '',
    avatar: ''
  };

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

  aboutToAppear() {
    this.loadServerIP()
    this.loadUserProfile();
  }

  build() {
    Column() {
      // 顶部导航栏
      this.BuildHeader()

      if (this.isLoading) {
        this.BuildLoading()
      } else if (this.isError) {
        this.BuildError()
      } else {
        // 用户信息区域
        this.BuildUserInfo()

        // 数据统计卡片
        this.BuildStatsCard()

        // 功能列表
        this.BuildFunctionList()

        // 退出登录按钮
        this.BuildLogoutButton()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder BuildHeader() {
    Row() {
      Image($r('app.media.startIcon'))
        .width(24)
        .height(24)
        .fillColor('#333333')
        .onClick(() => {
          router.back();
        })

      Text('个人中心')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder BuildLoading() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color('#007DFF')

      Text('加载中...')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 16 })
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  @Builder BuildError() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(80)
        .height(80)
        .margin({ bottom: 16 })

      Text(this.errorMessage || '加载失败')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 20 })

      Button('重新加载')
        .type(ButtonType.Capsule)
        .width(120)
        .height(36)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => {
          this.loadUserProfile();
        })
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  @Builder BuildUserInfo() {
    Column({ space: 20 }) {
      // 头像和基本信息
      Row() {
        // 头像
        Stack() {
          // 头像显示
          this.BuildAvatar()

          // 头像上传加载状态
          if (this.isUploadingAvatar) {
            Column() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(Color.White)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('rgba(0,0,0,0.5)')
            .borderRadius(40)
          }

          // 头像编辑按钮
          Column() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
          }
          .width(30)
          .height(30)
          .backgroundColor('#007DFF')
          .borderRadius(15)
          .align(Alignment.BottomEnd)
          .onClick(() => {
            this.changeAvatar();
          })
        }
        .width(80)
        .height(80)

        // 用户信息
        Column({ space: 8 }) {
          Text(this.getUserNickName())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Row() {
            Text('ID: ')
              .fontSize(14)
              .fontColor('#666666')
            Text(this.userInfo.userId || this.storedUserInfo.userId)
              .fontSize(14)
              .fontColor('#666666')
              .fontWeight(FontWeight.Medium)
          }

          Row() {
            Text('手机: ')
              .fontSize(14)
              .fontColor('#666666')
            Text(this.userInfo.phone || '未绑定')
              .fontSize(14)
              .fontColor(this.userInfo.phone ? '#333333' : '#999999')
          }
        }
        .layoutWeight(1)
        .margin({ left: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder BuildAvatar() {
    Image(this.userInfo.avatar || this.storedUserInfo.avatar || $r('app.media.startIcon'))
      .width(80)
      .height(80)
      .borderRadius(40)
      .objectFit(ImageFit.Cover)
  }

  @Builder BuildStatsCard() {
    Column({ space: 16 }) {
      // 积分和签到统计
      Row() {
        Column({ space: 8 }) {
          Row() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .fillColor('#FF6B35')
              .margin({ right: 8 })
            Text('我的积分')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Text(this.userInfo.totalPoints.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B35')
        }
        .layoutWeight(1)

        Column({ space: 8 }) {
          Row() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .fillColor('#52C41A')
              .margin({ right: 8 })
            Text('打卡天数')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Text(`${this.userInfo.checkInCount}天`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#52C41A')
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 等级信息
      Row() {
        Text('当前等级: ')
          .fontSize(14)
          .fontColor('#666666')
        Text(this.getUserLevel())
          .fontSize(14)
          .fontColor('#FA8C16')
          .fontWeight(FontWeight.Medium)

        Blank()

        Text('查看等级权益 >')
          .fontSize(12)
          .fontColor('#007DFF')
          .onClick(() => {
            this.viewLevelBenefits();
          })
      }
      .width('100%')
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder BuildFunctionList() {
    Column() {
      // 打卡相关功能
      this.BuildFunctionItem('打卡记录', $r('app.media.startIcon'), '查看签到历史', () => {
        this.viewCheckInHistory();
      })

      // 账户安全
      this.BuildFunctionItem('账户安全', $r('app.media.startIcon'), '修改密码等', () => {
        this.accountSecurity();
      })

      // 系统设置
      this.BuildFunctionItem('设置', $r('app.media.startIcon'), '应用设置', () => {
        this.openSettings();
      })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder BuildFunctionItem(title: string, icon: Resource, desc: string, onClick: () => void) {
    Row() {
      // 图标
      Image(icon)
        .width(24)
        .height(24)
        .fillColor('#007DFF')
        .margin({ right: 12 })

      // 标题和描述
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')
          .textAlign(TextAlign.Start)
          .width('100%')

        Text(desc)
          .fontSize(12)
          .fontColor('#999999')
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头
      Image($r('app.media.startIcon'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .onClick(onClick)

    // 分割线
    Divider()
      .width('100%')
      .color('#F5F5F5')
      .margin({ left: 52 })
  }

  @Builder BuildLogoutButton() {
    Button('退出登录')
      .type(ButtonType.Normal)
      .width('90%')
      .height(44)
      .backgroundColor('#FF4D4F')
      .fontColor(Color.White)
      .fontSize(16)
      .margin({ top: 30, bottom: 40 })
      .onClick(() => {
        this.handleLogout();
      })
  }

  // 加载用户资料
  private async loadUserProfile() {
    this.isLoading = true;
    this.isError = false;

    try {
      // 从 AppStorage 获取 token
      const token = this.storedUserInfo.token;

      if (!token) {
        this.isError = true;
        this.errorMessage = '请先登录';
        this.isLoading = false;
        return;
      }

      // 创建HTTP请求
      let httpRequest = http.createHttp();
      let url = 'http://' + `${this.serverIP}` + '/api/user/profile';

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        readTimeout: 60000,
        connectTimeout: 60000
      } as http.HttpRequestOptions;

      httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
        this.isLoading = false;

        if (err) {
          console.error('请求失败: ' + JSON.stringify(err));
          this.isError = true;
          this.errorMessage = '网络请求失败';
          return;
        }

        if (data.responseCode === 200) {
          try {
            const resultString: string = data.result.toString();
            const result: ProfileApiResponse = JSON.parse(resultString) as ProfileApiResponse;

            console.log('用户资料响应:', result);

            if (result.success === true) {
              this.updateUserInfo(result.data);
            } else {
              this.isError = true;
              this.errorMessage = result.message || '获取用户信息失败';
            }
          } catch (parseError) {
            console.error('数据解析失败:', parseError);
            this.isError = true;
            this.errorMessage = '数据解析失败';
          }
        } else {
          this.isError = true;
          this.errorMessage = `请求失败: ${data.responseCode}`;
        }

        httpRequest.destroy();
      });
    } catch (error) {
      this.isLoading = false;
      this.isError = true;
      this.errorMessage = '网络异常';
      console.error('加载用户资料异常: ' + JSON.stringify(error));
    }
  }

  // 更新用户信息
  private updateUserInfo(data: UserProfileData): void {
    this.userInfo = {
      userId: data.userId?.toString() || '',
      nickName: data.nickName || '',
      avatar: data.avatar || '',
      phone: data.phone || '',
      totalPoints: data.totalPoints || 0,
      checkInCount: data.checkInCount || 0
    };

    if (data.nickName || data.avatar) {
      this.updateStoredUserInfo(data.nickName, data.avatar);
    }
  }

  // 更新本地存储的用户信息
  private updateStoredUserInfo(nickName: string, avatar: string): void {
    try {
      const updatedInfo: StoredUserData = {
        userId: this.storedUserInfo.userId,
        token: this.storedUserInfo.token,
        nickName: nickName || this.storedUserInfo.nickName,
        avatar: avatar || this.storedUserInfo.avatar
      };
      AppStorage.setOrCreate('userInfo', updatedInfo);
    } catch (error) {
      console.error('更新本地用户信息失败:', error);
    }
  }

  // 更换头像
  private async changeAvatar() {
    try {
      // 创建图片选择器
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const imageUri = photoSelectResult.photoUris[0];
        console.log('选择的图片URI:', imageUri);

        // 上传头像
        await this.uploadAvatar(imageUri);
      }
    } catch (error) {
      console.error('选择图片失败:', error);
      this.showError('选择图片失败，请重试');
    }
  }

  // 上传头像到服务器
  private async uploadAvatar(imageUri: string) {
    this.isUploadingAvatar = true;

    try {
      // 从 AppStorage 获取 token
      const token = this.storedUserInfo.token;
      if (!token) {
        this.showError('请先登录');
        return;
      }

      // 这里需要先上传图片到文件服务器获取URL
      // 假设我们已经获得了图片URL
      const avatarUrl = await this.uploadImageToServer(imageUri);

      if (!avatarUrl) {
        this.showError('图片上传失败');
        return;
      }

      // 调用更新头像接口
      const httpRequest = http.createHttp();
      const url = 'http://' + `${this.serverIP}` + '/api/user/avatar';

      // 使用显式类型声明的请求数据
      const requestData: AvatarUpdateRequest = {
        avatarUrl: avatarUrl
      };

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(requestData),
        readTimeout: 60000,
        connectTimeout: 60000
      } as http.HttpRequestOptions;

      httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
        this.isUploadingAvatar = false;

        if (err) {
          console.error('上传头像失败: ' + JSON.stringify(err));
          this.showError('上传头像失败');
          return;
        }

        if (data.responseCode === 200) {
          try {
            const resultString: string = data.result.toString();
            const result: AvatarUpdateResponse = JSON.parse(resultString) as AvatarUpdateResponse;

            if (result.success === true) {
              console.log('头像更新成功');
              this.showSuccess('头像更新成功');

              // 更新本地头像显示
              this.userInfo.avatar = avatarUrl;
              this.updateStoredUserInfo(this.userInfo.nickName, avatarUrl);

              // 重新加载用户资料确保数据同步
              this.loadUserProfile();
            } else {
              this.showError(result.message || '头像更新失败');
            }
          } catch (parseError) {
            console.error('数据解析失败:', parseError);
            this.showError('数据解析失败');
          }
        } else {
          this.showError(`上传失败: ${data.responseCode}`);
        }

        httpRequest.destroy();
      });

    } catch (error) {
      this.isUploadingAvatar = false;
      console.error('上传头像异常: ' + JSON.stringify(error));
      this.showError('上传头像失败');
    }
  }

  // 模拟图片上传到文件服务器（实际项目中需要实现真实的文件上传）
  private async uploadImageToServer(imageUri: string): Promise<string> {
    return new Promise((resolve) => {
      // 模拟上传过程
      setTimeout(() => {
        // 生成模拟的云端URL
        const fileName = `avatar_${Date.now()}.jpg`;
        const cloudUrl = `cloud://bucket/${fileName}`;
        console.log('模拟上传成功，返回URL:', cloudUrl);
        resolve(cloudUrl);
      }, 1000);
    });
  }

  // 显示成功消息
  private showSuccess(message: string) {
    // 这里可以使用Toast或者自定义提示
    console.log('成功:', message);
    // 实际项目中可以添加Toast提示
    // prompt.showToast({ message: message, duration: 2000 });
  }

  // 显示错误消息
  private showError(message: string) {
    console.error('错误:', message);
    this.errorMessage = message;
    this.isError = true;
    // 实际项目中可以添加Toast提示
    // prompt.showToast({ message: message, duration: 3000 });
  }

  // 获取用户头像URL
  private getUserAvatarUrl(): string {
    if (this.userInfo.avatar) {
      return this.userInfo.avatar;
    }
    return this.storedUserInfo.avatar || '';
  }

  // 获取用户昵称
  private getUserNickName(): string {
    if (this.userInfo.nickName && this.userInfo.nickName !== '加载中...') {
      return this.userInfo.nickName;
    }
    return this.storedUserInfo.nickName || '用户';
  }

  // 获取用户等级
  private getUserLevel(): string {
    const points = this.userInfo.totalPoints;
    if (points >= 1000) return '钻石会员';
    if (points >= 500) return '黄金会员';
    if (points >= 100) return '白银会员';
    return '普通会员';
  }

  // 查看签到记录
  private viewCheckInHistory() {
    router.pushUrl({
      url: 'pages/CheckInHistory'
    });
  }

  // 查看等级权益
  private viewLevelBenefits() {
    router.pushUrl({
      url: 'pages/LevelBenefits'
    });
  }

  // 账户安全
  private accountSecurity() {
    router.pushUrl({
      url: 'pages/AccountSecurity'
    });
  }

  // 打开设置
  private openSettings() {
    router.pushUrl({
      url: 'pages/Settings'
    });
  }

  // 退出登录
  private handleLogout() {
    this.clearUserData();
    router.replaceUrl({
      url: 'pages/Login'
    });
  }

  // 清除用户数据
  private clearUserData() {
    try {
      AppStorage.setOrCreate('userToken', '');
      AppStorage.setOrCreate('userInfo', {
        userId: '',
        token: '',
        nickName: '',
        avatar: ''
      });
      console.log('用户数据已清除');
    } catch (error) {
      console.error('清除用户数据失败:', error);
    }
  }
}