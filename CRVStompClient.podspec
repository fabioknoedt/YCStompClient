Pod::Spec.new do |spec|
  spec.name             = 'CRVStompClient'
  spec.version          = '1.0'
  spec.license          =  :type => 'BSD' 
  spec.homepage         = 'https://github.com/fabioknoedt/objc-stomp'
  spec.authors          = 'Fabio Knoedt' => 'fabioknoedt@gmail.com'
  spec.summary          = 'This is a simple STOMP client based on [https://github.com/juretta/objc-stomp] that supports Stomp v1.1 and v1.2.'
  spec.source           =  :git => 'https://github.com/fabioknoedt/objc-stomp.git', :tag => 'v1.0'
  spec.source_files     = 'CRVStompClient.h,m'
  spec.requires_arc     = true
  spec.dependency       'SocketRocket'
end