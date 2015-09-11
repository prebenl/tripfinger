from __future__ import print_function

from ResponseProvider import Payload
from ResponseProvider import ResponseProvider
from ResponseProvider import ResponseProviderMixin
from threading import Timer
import threading
import tornado.ioloop
import tornado.web


class MainHandler(tornado.web.RequestHandler, ResponseProviderMixin):
    
    ping_count = 1
    self_destruct_timer = None
    
    def got_pinged(self):
        MainHandler.ping_count += 1

        
    def kill(self):
        MainHandler.ping_count -= 1
        if MainHandler.ping_count <= 0: #so that if we decrease the value from several threads we still kill it.
            tornado.ioloop.IOLoop.current().stop()
            if MainHandler.self_destruct_timer:
                MainHandler.self_destruct_timer.cancel()
        

    def dispatch_response(self, payload):
        self.set_status(payload.response_code())
        for h in payload.headers():
            self.add_header(h, payload.headers()[h])
        self.add_header("Content-Length", payload.length())
        self.write(payload.message())
    
    
    def prepare_headers(self):
        ret = dict()
        for h in self.request.headers:
            ret[h.lower()] = self.request.headers.get(h)
            
        return ret
    
    
    def init_vars(self):
        self.response_provider = ResponseProvider(self)
        self.headers = self.prepare_headers()
        
    
    def prepare(self):
        MainHandler.reset_self_destruct_timer()
        self.init_vars()


    def get(self, param):
        self.dispatch_response(self.response_provider.response_for_url_and_headers(self.request.uri, self.headers))
        

    def post(self, param):
        self.dispatch_response(Payload(self.request.body))


    @staticmethod
    def reset_self_destruct_timer():
        if MainHandler.self_destruct_timer:
            MainHandler.self_destruct_timer.cancel()
        MainHandler.self_destruct_timer = Timer(MainHandler.lifespan, tornado.ioloop.IOLoop.current().stop)
        MainHandler.self_destruct_timer.start()
    
    
    @staticmethod
    def start_serving():
        thread = threading.Thread(target=tornado.ioloop.IOLoop.current().start)
        thread.deamon = True
        thread.start()
        
    
    @staticmethod
    def init_server(port, lifespan):
        MainHandler.lifespan = lifespan
        MainHandler.reset_self_destruct_timer()
        application = tornado.web.Application([
            (r"/(.*)", MainHandler),
        ])
        application.listen(port)