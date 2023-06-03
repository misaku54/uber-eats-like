import logo from './logo.svg';
import './App.css';
import {
  BrouserRouter as Router,
  Switch,
  Route,
} from 'react-router-dom';

import { Restaurants } from './containers/Restaurants';
import { Foods } from './containers/Foods';
import { Orders } from './containers/Orders';

function App() {
  return (
    <Router>
      <Switch>
        <Route exact path="/restaurants">
          <Restaurants />
        </Route>
        <Route exact path="/foods">
          <Foods />
        </Route>
        <Route exact path="/orders">
          <Orders />
        </Route>
      </Switch>
    </Router>
  );
}

export default App;
